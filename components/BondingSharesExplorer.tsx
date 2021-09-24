import { BigNumber, ethers } from "ethers";
import { memo, useState, useCallback } from "react";
import { connectedWithUserContext, UserContext } from "./context/connected";
import { formatEther } from "./common/format";
import { useAsyncInit, performTransaction } from "./common/utils";
import * as widget from "./ui/widget";
import { UBQIcon, LiquidIcon } from "./ui/icons";

type ShareData = {
  id: number;
  ugov: BigNumber;
  bond: {
    minter: string;
    lpFirstDeposited: BigNumber;
    creationBlock: BigNumber;
    lpRewardDebt: BigNumber;
    endBlock: BigNumber;
    lpAmount: BigNumber;
  };
  sharesBalance: BigNumber;
  weeksLeft: number;
};

type Model = {
  shares: ShareData[];
  totalShares: BigNumber;
  transacting: boolean;
};

type Actions = { onWithdrawLp: (payload: { id: number; amount: null | number }) => void; onClaimUbq: (id: number) => void };

export const BondingSharesExplorerContainer = ({ contracts, provider, account, signer }: UserContext) => {
  const [model, setModel] = useState<Model | null>(null);

  useAsyncInit(fetchSharesInformation);
  async function fetchSharesInformation() {
    console.time("BondingShareExplorerContainer contract loading");
    const currentBlock = await provider.getBlockNumber();
    const blockCountInAWeek = +(await contracts.bonding.blockCountInAWeek()).toString();
    const totalShares = await contracts.masterChef.totalShares();
    const bondingShareIds = await contracts.bondingToken.holderTokens(account.address);

    const shares: ShareData[] = [];
    await Promise.all(
      bondingShareIds.map(async (id) => {
        const [ugov, bond, bondingShareInfo, tokenBalance] = await Promise.all([
          contracts.masterChef.pendingUGOV(id),
          contracts.bondingToken.getBond(id),
          contracts.masterChef.getBondingShareInfo(id),
          contracts.bondingToken.balanceOf(account.address, id),
        ]);

        const endBlock = +bond.endBlock.toString();
        const blocksLeft = endBlock - currentBlock;
        const weeksLeft = Math.round((blocksLeft / blockCountInAWeek) * 100) / 100;

        // If this is 0 it means the share ERC1155 token was transferred to another account
        if (+tokenBalance.toString() > 0) {
          shares.push({ id: +id.toString(), ugov, bond, sharesBalance: bondingShareInfo[0], weeksLeft });
        }
      })
    );

    const sortedShares = shares.sort((a, b) => a.id - b.id);

    console.timeEnd("BondingShareExplorerContainer contract loading");
    setModel({ transacting: false, shares: sortedShares, totalShares });
  }

  function allLpAmount(id: number): BigNumber {
    if (!model) throw new Error("No model");
    const lpAmount = model.shares.find((s) => s.id === id)?.bond?.lpAmount;
    if (!lpAmount) throw new Error("Could not find share in model");
    return lpAmount;
  }

  const actions: Actions = {
    onWithdrawLp: useCallback(
      async ({ id, amount }) => {
        if (!model || model.transacting) return;
        console.log(`Withdrawing ${amount ? amount : "ALL"} LP from ${id}`);
        setModel({ ...model, transacting: true });

        const isAllowed = await contracts.bondingToken.isApprovedForAll(account.address, contracts.bonding.address);
        if (!isAllowed) {
          // Allow bonding contract to control account share
          if (!(await performTransaction(contracts.bondingToken.connect(signer).setApprovalForAll(contracts.bonding.address, true)))) {
            return; // TODO: Show transaction errors to user
          }
        }

        const bigNumberAmount = amount ? ethers.utils.parseEther(amount.toString()) : allLpAmount(id);
        await performTransaction(contracts.bonding.connect(signer).removeLiquidity(bigNumberAmount, BigNumber.from(id)));

        fetchSharesInformation();
      },
      [model, contracts, signer]
    ),

    onClaimUbq: useCallback(
      async (id) => {
        if (!model || model.transacting) return;
        console.log(`Claiming UBQ rewards from ${id}`);
        setModel({ ...model, transacting: true });

        await performTransaction(contracts.masterChef.connect(signer).getRewards(BigNumber.from(id)));

        fetchSharesInformation();
      },
      [model, contracts, signer]
    ),
  };

  return <BondingSharesExplorer model={model} actions={actions} />;
};

export const BondingSharesExplorer = memo(({ model, actions }: { model: Model | null; actions: Actions }) => {
  console.log("Rendering BondingSharesExplorer", model);
  return (
    <widget.Container className="max-w-screen-md !mx-auto relative" transacting={model?.transacting}>
      <widget.Title text="Liquidity Tokens Staking" />
      {model ? <BondingSharesInformation {...model} {...actions} /> : <widget.Loading text="Loading existing shares information" />}
    </widget.Container>
  );
});

export const BondingSharesInformation = ({ shares, totalShares, onWithdrawLp, onClaimUbq }: Model & Actions) => {
  const totalUserShares = shares.reduce((sum, val) => {
    return sum.add(val.sharesBalance);
  }, BigNumber.from(0));

  const totalLpBalance = shares.reduce((sum, val) => {
    return sum.add(val.bond.lpAmount);
  }, BigNumber.from(0));

  const totalPendingUgov = shares.reduce((sum, val) => {
    return sum.add(val.ugov);
  }, BigNumber.from(0));

  const poolPercentage = formatEther(totalUserShares.mul(ethers.utils.parseEther("100")).div(totalShares));

  return (
    <div className="flex flex-col relative">
      <table className="border border-solid border-white border-opacity-10 border-collapse mb-4">
        <thead>
          <tr className="border-0 border-b border-solid border-white border-opacity-10 h-12">
            <th>ID</th>
            <th>Pending Reward</th>
            <th>LP</th>
            <th>Shares</th>
            <th>Time left</th>
            <th></th>
          </tr>
        </thead>
        {shares.length > 0 ? (
          <tbody>
            {shares.map((share) => (
              <BondingShareRow key={share.id} {...share} onWithdrawLp={onWithdrawLp} onClaimUbq={onClaimUbq} />
            ))}
          </tbody>
        ) : (
          <tbody>
            <tr>
              <td className="py-4" colSpan={5}>
                Nothing staked yet
              </td>
            </tr>
          </tbody>
        )}
      </table>
      <div className="text-white">
        <div className="mb-2 ">
          {UBQIcon}
          <span className="text-accent">{formatEther(totalPendingUgov)} </span>
          pending UBQ rewards
        </div>
        <div className="mb-2">
          {LiquidIcon}
          {formatEther(totalLpBalance)} LP locked in Bonding Shares
        </div>
        <div className="mb-2">{poolPercentage}% pool ownership.</div>
      </div>
    </div>
  );
};

const BondingShareRow = ({ id, ugov, sharesBalance, bond, weeksLeft, onWithdrawLp, onClaimUbq }: ShareData & Actions) => {
  const [withdrawAmount, setWithdrawAmount] = useState("");

  return (
    <tr key={id} className="h-12">
      <td className="pl-2">{id.toString()}</td>
      <td>
        <div className="text-accent whitespace-nowrap">
          {UBQIcon} <span>{formatEther(ugov)}</span>
        </div>
      </td>
      <td className="text-white">{formatEther(bond.lpAmount)}</td>
      <td className="text-white">{formatEther(sharesBalance)}</td>
      <td>
        {weeksLeft <= 0 ? (
          bond.lpAmount.gt(0) ? (
            <>
              <input type="text" placeholder="All" className="!min-w-0 !w-10" value={withdrawAmount} onChange={(ev) => setWithdrawAmount(ev.target.value)} />
              <button onClick={() => onWithdrawLp({ id, amount: parseFloat(withdrawAmount) || null })}>Withdraw</button>
            </>
          ) : null
        ) : (
          <span>{weeksLeft}w</span>
        )}
      </td>
      <td>{ugov.gt(0) ? <button onClick={() => onClaimUbq(+id.toString())}>Claim</button> : null}</td>
    </tr>
  );
};

export default connectedWithUserContext(BondingSharesExplorerContainer);
