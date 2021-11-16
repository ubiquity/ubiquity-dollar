import { BigNumber, ethers } from "ethers";
import { memo, useState, useCallback } from "react";
import { connectedWithUserContext, useConnectedContext, UserContext } from "./context/connected";
import { formatEther } from "./common/format";
import { useAsyncInit, performTransaction } from "./common/utils";
import * as widget from "./ui/widget";
import icons from "./ui/icons";
import DepositShare from "./DepositShare";

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
  walletLpBalance: BigNumber;
  processing: boolean;
};

type Actions = {
  onWithdrawLp: (payload: { id: number; amount: null | number }) => void;
  onClaimUbq: (id: number) => void;
  onStake: (payload: { amount: BigNumber; weeks: BigNumber }) => void;
};

const USD_TO_LP = 0.75;
const LP_TO_USD = 1 / USD_TO_LP;

export const BondingSharesExplorerContainer = ({ contracts, provider, account, signer }: UserContext) => {
  const [model, setModel] = useState<Model | null>(null);
  const { refreshBalances } = useConnectedContext();

  useAsyncInit(fetchSharesInformation);
  async function fetchSharesInformation() {
    console.time("BondingShareExplorerContainer contract loading");
    const currentBlock = await provider.getBlockNumber();
    const blockCountInAWeek = +(await contracts.bonding.blockCountInAWeek()).toString();
    const totalShares = await contracts.masterChef.totalShares();
    const bondingShareIds = await contracts.bondingToken.holderTokens(account.address);
    const walletLpBalance = await contracts.metaPool.balanceOf(account.address);

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
    setModel({ processing: false, shares: sortedShares, totalShares, walletLpBalance });
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
        if (!model || model.processing) return;
        console.log(`Withdrawing ${amount ? amount : "ALL"} LP from ${id}`);
        setModel({ ...model, processing: true });

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
        refreshBalances();
      },
      [model, contracts, signer]
    ),

    onClaimUbq: useCallback(
      async (id) => {
        if (!model || model.processing) return;
        console.log(`Claiming UBQ rewards from ${id}`);
        setModel({ ...model, processing: true });

        await performTransaction(contracts.masterChef.connect(signer).getRewards(BigNumber.from(id)));

        fetchSharesInformation();
        refreshBalances();
      },
      [model, contracts, signer]
    ),

    onStake: useCallback(
      async ({ amount, weeks }) => {
        if (!model || model.processing) return;
        console.log(`Staking ${amount} for ${weeks} weeks`);
        setModel({ ...model, processing: true });
        const allowance = await contracts.metaPool.allowance(account.address, contracts.bonding.address);
        console.log("allowance", ethers.utils.formatEther(allowance));
        console.log("lpsAmount", ethers.utils.formatEther(amount));
        if (allowance.lt(amount)) {
          await performTransaction(contracts.metaPool.connect(signer).approve(contracts.bonding.address, amount));
          const allowance2 = await contracts.metaPool.allowance(account.address, contracts.bonding.address);
          console.log("allowance2", ethers.utils.formatEther(allowance2));
        }
        await performTransaction(contracts.bonding.connect(signer).deposit(amount, weeks));

        fetchSharesInformation();
        refreshBalances();
      },
      [model, contracts, signer]
    ),
  };

  return <BondingSharesExplorer model={model} actions={actions} />;
};

export const BondingSharesExplorer = memo(({ model, actions }: { model: Model | null; actions: Actions }) => {
  return (
    <widget.Container className="max-w-screen-md !mx-auto relative" transacting={model?.processing}>
      <widget.Title text="Liquidity Mining" />
      {model ? <BondingSharesInformation {...model} {...actions} /> : <widget.Loading text="Loading existing shares information" />}
    </widget.Container>
  );
});

export const BondingSharesInformation = ({ shares, totalShares, onWithdrawLp, onClaimUbq, onStake, processing, walletLpBalance }: Model & Actions) => {
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

  const filteredShares = shares.filter(({ bond: { lpAmount }, ugov }) => lpAmount.gt(0) || ugov.gt(0));

  return (
    <div className="flex flex-col relative">
      <DepositShare onStake={onStake} disabled={processing} maxLp={walletLpBalance} />
      <table>
        <thead>
          <tr>
            <th>Deposit (Approx.)</th>
            <th>Pending Reward</th>
            <th>Unlock Time</th>
            <th>Action</th>
          </tr>
        </thead>
        {filteredShares.length > 0 ? (
          <tbody>
            {filteredShares.map((share) => (
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
      <div id="rewards-summary">
        <div className="mb-2 inline-flex items-center">
          {icons.svgs.ubq}
          <span className="text-accent">{formatEther(totalPendingUgov)} </span>
          &nbsp;pending UBQ rewards
        </div>
        <div className="mb-2">
          {icons.svgs.lp}
          {formatEther(totalLpBalance)} LP locked in Bonding Shares
        </div>
        <div className="mb-2">{poolPercentage}% pool ownership</div>
      </div>
    </div>
  );
};

type BondingShareRowProps = ShareData & { onWithdrawLp: Actions["onWithdrawLp"]; onClaimUbq: Actions["onClaimUbq"] };
const BondingShareRow = ({ id, ugov, sharesBalance, bond, weeksLeft, onWithdrawLp, onClaimUbq }: BondingShareRowProps) => {
  const [withdrawAmount, setWithdrawAmount] = useState("");

  const numLpAmount = +formatEther(bond.lpAmount);
  const usdAmount = numLpAmount * LP_TO_USD;

  function onClickWithdraw() {
    const parsedUsdAmount = parseFloat(withdrawAmount);
    if (parsedUsdAmount) {
      onWithdrawLp({ id, amount: parsedUsdAmount * USD_TO_LP });
    } else {
      onWithdrawLp({ id, amount: null });
    }
  }

  return (
    <tr key={id} className="h-12" title={id.toString()}>
      <td className="text-white" title={`LP = ${numLpAmount} | Shares = ${formatEther(sharesBalance)} | 1 USD = ${USD_TO_LP} LP`}>
        ${Math.round(usdAmount * 100) / 100}
      </td>
      <td>
        <div className="text-accent whitespace-nowrap inline-flex items-center">
          {icons.svgs.ubq} <span>{formatEther(ugov)}</span>
        </div>
      </td>
      <td>{weeksLeft <= 0 ? "Ready" : <span>{weeksLeft}w</span>}</td>
      <td>
        {weeksLeft <= 0 && bond.lpAmount.gt(0) ? (
          <>
            {/* <input type="text" placeholder="All" className="!min-w-0 !w-10" value={withdrawAmount} onChange={(ev) => setWithdrawAmount(ev.target.value)} /> */}
            <button onClick={onClickWithdraw}>Claim &amp; Withdraw</button>
          </>
        ) : ugov.gt(0) ? (
          <button onClick={() => onClaimUbq(+id.toString())}>Claim reward</button>
        ) : null}
      </td>
    </tr>
  );
};

export default connectedWithUserContext(BondingSharesExplorerContainer);
