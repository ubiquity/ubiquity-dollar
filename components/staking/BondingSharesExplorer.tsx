import { BigNumber, ethers } from "ethers";
import { memo, useCallback, useState } from "react";

import { formatEther } from "@/lib/format";
import { performTransaction, useAsyncInit } from "@/lib/utils";
import withLoadedContext, { LoadedContext } from "@/lib/withLoadedContext";

// Contracts: bonding, metaPool, bondingToken, masterChef

import DepositShare from "./DepositShare";
import useBalances from "../lib/hooks/useBalances";
import useTransactionLogger from "../lib/hooks/useTransactionLogger";
import Button from "../ui/Button";
import Icon from "../ui/Icon";
import Loading from "../ui/Loading";

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

const USD_TO_LP = 0.7460387929;
const LP_TO_USD = 1 / USD_TO_LP;

export const BondingSharesExplorerContainer = ({ managedContracts, web3Provider, walletAddress, signer }: LoadedContext) => {
  const [model, setModel] = useState<Model | null>(null);
  const [, doTransaction] = useTransactionLogger();
  const [, refreshBalances] = useBalances();

  const { bonding, masterChef, bondingToken, metaPool } = managedContracts;

  useAsyncInit(fetchSharesInformation);
  async function fetchSharesInformation() {
    console.time("BondingShareExplorerContainer contract loading");
    const currentBlock = await web3Provider.getBlockNumber();
    const blockCountInAWeek = +(await bonding.blockCountInAWeek()).toString();
    const totalShares = await masterChef.totalShares();
    const bondingShareIds = await bondingToken.holderTokens(walletAddress);
    const walletLpBalance = await metaPool.balanceOf(walletAddress);

    const shares: ShareData[] = [];
    await Promise.all(
      bondingShareIds.map(async (id) => {
        const [ugov, bond, bondingShareInfo, tokenBalance] = await Promise.all([
          masterChef.pendingUGOV(id),
          bondingToken.getBond(id),
          masterChef.getBondingShareInfo(id),
          bondingToken.balanceOf(walletAddress, id),
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
        doTransaction("Withdrawing LP...", async () => {
          const isAllowed = await bondingToken.isApprovedForAll(walletAddress, bonding.address);
          if (!isAllowed) {
            // Allow bonding contract to control account share
            if (!(await performTransaction(bondingToken.connect(signer).setApprovalForAll(bonding.address, true)))) {
              return; // TODO: Show transaction errors to user
            }
          }

          const bigNumberAmount = amount ? ethers.utils.parseEther(amount.toString()) : allLpAmount(id);
          await performTransaction(bonding.connect(signer).removeLiquidity(bigNumberAmount, BigNumber.from(id)));

          fetchSharesInformation();
          refreshBalances();
        });
      },
      [model]
    ),

    onClaimUbq: useCallback(
      async (id) => {
        if (!model || model.processing) return;
        console.log(`Claiming UBQ rewards from ${id}`);
        setModel({ ...model, processing: true });
        doTransaction("Claiming UBQ...", async () => {
          await performTransaction(masterChef.connect(signer).getRewards(BigNumber.from(id)));

          fetchSharesInformation();
          refreshBalances();
        });
      },
      [model]
    ),

    onStake: useCallback(
      async ({ amount, weeks }) => {
        if (!model || model.processing) return;
        console.log(`Staking ${amount} for ${weeks} weeks`);
        setModel({ ...model, processing: true });
        doTransaction("Staking...", async () => {});
        const allowance = await metaPool.allowance(walletAddress, bonding.address);
        console.log("allowance", ethers.utils.formatEther(allowance));
        console.log("lpsAmount", ethers.utils.formatEther(amount));
        if (allowance.lt(amount)) {
          await performTransaction(metaPool.connect(signer).approve(bonding.address, amount));
          const allowance2 = await metaPool.allowance(walletAddress, bonding.address);
          console.log("allowance2", ethers.utils.formatEther(allowance2));
        }
        await performTransaction(bonding.connect(signer).deposit(amount, weeks));

        fetchSharesInformation();
        refreshBalances();
      },
      [model]
    ),
  };

  return <BondingSharesExplorer model={model} actions={actions} />;
};

export const BondingSharesExplorer = memo(({ model, actions }: { model: Model | null; actions: Actions }) => {
  return (
    <div className="panel">
      <h2>Stake liquidity to receive UBQ</h2>
      {model ? <BondingSharesInformation {...model} {...actions} /> : <Loading text="Loading existing shares information" />}
    </div>
  );
});

export const BondingSharesInformation = ({ shares, totalShares, onWithdrawLp, onClaimUbq, onStake, processing, walletLpBalance }: Model & Actions) => {
  const totalUserShares = shares.reduce((sum, val) => {
    return sum.add(val.sharesBalance);
  }, BigNumber.from(0));

  const totalLpBalance = shares.reduce((sum, val) => {
    return sum.add(val.bond.lpAmount);
  }, BigNumber.from(0));

  const totalPendingUgov = shares.reduce((sum, val) => sum.add(val.ugov), BigNumber.from(0));

  const poolPercentage = formatEther(totalUserShares.mul(ethers.utils.parseEther("100")).div(totalShares));

  const filteredShares = shares.filter(({ bond: { lpAmount }, ugov }) => lpAmount.gt(0) || ugov.gt(0));

  return (
    <div>
      <DepositShare onStake={onStake} disabled={processing} maxLp={walletLpBalance} />
      <div>
        <table id="Staking">
          <thead>
            <tr>
              <th>Est. Deposit</th>
              <th>Rewards</th>
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
                <td colSpan={5}>Nothing staked yet</td>
              </tr>
            </tbody>
          )}
        </table>
      </div>

      <table>
        <tbody>
          <tr>
            <td>
              <span>Pending</span>
            </td>
            <td>
              <Icon icon="ubq" />
            </td>
            <td>
              <span>{formatEther(totalPendingUgov)} </span>
            </td>
          </tr>
          <tr>
            <td>
              <span>Staked LP</span>
            </td>
            <td>
              <Icon icon="liquidity" />
            </td>
            <td>{formatEther(totalLpBalance)}</td>
          </tr>
          <tr>
            <td>Ownership</td>
            <td>%</td>
            <td>{poolPercentage}</td>
          </tr>
        </tbody>
      </table>
    </div>
  );
};

type BondingShareRowProps = ShareData & { onWithdrawLp: Actions["onWithdrawLp"]; onClaimUbq: Actions["onClaimUbq"] };
const BondingShareRow = ({ id, ugov, sharesBalance, bond, weeksLeft, onWithdrawLp, onClaimUbq }: BondingShareRowProps) => {
  const [withdrawAmount] = useState("");

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
    <tr key={id} title={id.toString()}>
      <td title={`LP = ${numLpAmount} | Shares = ${formatEther(sharesBalance)} | 1 USD = ${USD_TO_LP} LP`}>${Math.round(usdAmount * 100) / 100}</td>
      <td>
        <div>
          <Icon icon="ubq" /> <span>{formatEther(ugov)}</span>
        </div>
      </td>
      <td>{weeksLeft <= 0 ? "Ready" : <span>{weeksLeft}w</span>}</td>
      <td>
        {weeksLeft <= 0 && bond.lpAmount.gt(0) ? (
          <>
            {/* <input type="text" placeholder="All" value={withdrawAmount} onChange={(ev) => setWithdrawAmount(ev.target.value)} /> */}
            <button onClick={onClickWithdraw}>Claim &amp; Withdraw</button>
          </>
        ) : ugov.gt(0) ? (
          <Button onClick={() => onClaimUbq(+id.toString())}>Claim reward</Button>
        ) : null}
      </td>
    </tr>
  );
};

export default withLoadedContext(BondingSharesExplorerContainer);
