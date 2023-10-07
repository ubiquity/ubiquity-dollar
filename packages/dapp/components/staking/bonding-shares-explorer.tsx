import { BigNumber, ethers } from "ethers";
import { memo, useCallback, useState } from "react";

import { formatEther } from "@/lib/format";
import { performTransaction, useAsyncInit } from "@/lib/utils";
import withLoadedContext, { LoadedContext } from "@/lib/with-loaded-context";

import DepositShare from "./deposit-share";
import useBalances from "../lib/hooks/use-balances";
import useTransactionLogger from "../lib/hooks/use-transaction-logger";
import Button from "../ui/button";
import Icon from "../ui/icon";
import Loading from "../ui/loading";

type ShareData = {
  id: number;
  // cspell: disable-next-line
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
  processing: ShareData["id"][];
};

type Actions = {
  onWithdrawLp: (payload: { id: number; amount: null | number }) => void;
  onClaimUbq: (id: number) => void;
  onStake: (payload: { amount: BigNumber; weeks: BigNumber }) => void;
};

const USD_TO_LP = 0.7460387929;
const LP_TO_USD = 1 / USD_TO_LP;

export const BondingSharesExplorerContainer = ({ protocolContracts, web3Provider, walletAddress, signer }: LoadedContext) => {
  const [model, setModel] = useState<Model | null>(null);
  const [, doTransaction] = useTransactionLogger();
  const [, refreshBalances] = useBalances();

  useAsyncInit(fetchSharesInformation);
  async function fetchSharesInformation(processedShareId?: ShareData["id"]) {
    // cspell: disable-next-line
    const { stakingFacet: bonding, chefFacet, stakingShare: bondingToken, curveMetaPoolDollarTriPoolLp } = await protocolContracts;
    if (bonding) {
      console.time("BondingShareExplorerContainer contract loading");
      const currentBlock = await web3Provider.getBlockNumber();
      // cspell: disable-next-line
      const blockCountInAWeek = +(await bonding.blockCountInAWeek()).toString();
      const totalShares = await chefFacet?.totalShares();
      // cspell: disable-next-line
      const bondingShareIds = await bondingToken?.holderTokens(walletAddress);

      const walletLpBalance = await curveMetaPoolDollarTriPoolLp?.balanceOf(walletAddress);

      const shares: ShareData[] = [];
      await Promise.all(
        // cspell: disable-next-line
        bondingShareIds.map(async (id: BigNumber) => {
          // cspell: disable-next-line
          const [ugov, bond, bondingShareInfo, tokenBalance] = await Promise.all([
            // cspell: disable-next-line
            chefFacet?.pendingGovernance(id),
            // cspell: disable-next-line
            bondingToken?.getStake(id),
            chefFacet?.getStakingShareInfo(id),
            // cspell: disable-next-line
            bondingToken?.balanceOf(walletAddress, id),
          ]);

          const endBlock = +bond.endBlock.toString();
          const blocksLeft = endBlock - currentBlock;
          const weeksLeft = Math.round((blocksLeft / blockCountInAWeek) * 100) / 100;

          // If this is 0 it means the share ERC1155 token was transferred to another account
          if (+tokenBalance.toString() > 0) {
            // cspell: disable-next-line
            shares.push({ id: +id.toString(), ugov, bond, sharesBalance: bondingShareInfo[0], weeksLeft });
          }
        })
      );

      const sortedShares = shares.sort((a, b) => a.id - b.id);

      console.timeEnd("BondingShareExplorerContainer contract loading");
      setModel((model) => ({
        processing: model ? model.processing.filter((id) => id !== processedShareId) : [],
        shares: sortedShares,
        totalShares,
        walletLpBalance,
      }));
    }
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
        const { stakingFacet: bonding, stakingShare: bondingToken } = await protocolContracts;
        if (!model || model.processing.includes(id)) return;
        console.log(`Withdrawing ${amount ? amount : "ALL"} LP from ${id}`);
        setModel((prevModel) => (prevModel ? { ...prevModel, processing: [...prevModel.processing, id] } : null));
        doTransaction("Withdrawing LP...", async () => {
          try {
            // cspell: disable-next-line
            const isAllowed = await bondingToken?.isApprovedForAll(walletAddress, bonding?.address);
            if (!isAllowed) {
              // cspell: disable-next-line
              // Allow bonding contract to control account share
              // cspell: disable-next-line
              if (!(await performTransaction(bondingToken?.connect(signer).setApprovalForAll(bonding?.address, true)))) {
                return; // TODO: Show transaction errors to user
              }
            }

            const bigNumberAmount = amount ? ethers.utils.parseEther(amount.toString()) : allLpAmount(id);
            // cspell: disable-next-line
            await performTransaction(bonding?.connect(signer).removeLiquidity(bigNumberAmount, BigNumber.from(id)));
          } catch (error) {
            console.log(`Withdrawing LP from ${id} failed:`, error);
            // throws exception to update the transaction log
            throw error;
          } finally {
            fetchSharesInformation(id);
            refreshBalances();
          }
        });
      },
      [model]
    ),

    onClaimUbq: useCallback(
      async (id) => {
        const { chefFacet } = await protocolContracts;
        if (!model) return;
        console.log(`Claiming Ubiquity Governance token rewards from ${id}`);
        setModel((prevModel) => (prevModel ? { ...prevModel, processing: [...prevModel.processing, id] } : null));
        doTransaction("Claiming Ubiquity Governance tokens...", async () => {
          try {
            await performTransaction(chefFacet?.connect(signer).getRewards(BigNumber.from(id)));
          } catch (error) {
            console.log(`Claiming Ubiquity Governance token rewards from ${id} failed:`, error);
            // throws exception to update the transaction log
            throw error;
          } finally {
            fetchSharesInformation(id);
            refreshBalances();
          }
        });
      },
      [model]
    ),

    onStake: useCallback(
      async ({ amount, weeks }) => {
        const { stakingFacet: bonding, curveMetaPoolDollarTriPoolLp } = await protocolContracts;
        if (!model || model.processing.length) return;
        console.log(`Staking ${amount} for ${weeks} weeks`);
        doTransaction("Staking...", async () => {});

        // cspell: disable-next-line
        const allowance = await curveMetaPoolDollarTriPoolLp?.allowance(walletAddress, bonding?.address);
        console.log("allowance", ethers.utils.formatEther(allowance));
        console.log("lpsAmount", ethers.utils.formatEther(amount));
        if (allowance.lt(amount)) {
          // cspell: disable-next-line
          await performTransaction(curveMetaPoolDollarTriPoolLp?.connect(signer).approve(bonding?.address, amount));
          // cspell: disable-next-line
          const allowance2 = await curveMetaPoolDollarTriPoolLp?.allowance(walletAddress, bonding?.address);
          console.log("allowance2", ethers.utils.formatEther(allowance2));
        }
        // cspell: disable-next-line
        await performTransaction(bonding?.connect(signer).deposit(amount, weeks));

        fetchSharesInformation();
        refreshBalances();
      },
      [model]
    ),
  };

  return <BondingSharesExplorer model={model} actions={actions} />;
};

export const BondingSharesExplorer = memo(({ model, actions }: { model: Model | null; actions: Actions }) => {
  return <>{model ? <BondingSharesInformation {...model} {...actions} /> : <Loading text="Loading existing shares information" />}</>;
});

export const BondingSharesInformation = ({ shares, totalShares, onWithdrawLp, onClaimUbq, onStake, processing, walletLpBalance }: Model & Actions) => {
  const totalUserShares = shares.reduce((sum, val) => {
    return sum.add(val.sharesBalance);
  }, BigNumber.from(0));

  const totalLpBalance = shares.reduce((sum, val) => {
    return sum.add(val.bond.lpAmount);
  }, BigNumber.from(0));
  // cspell: disable-next-line
  const totalPendingUgov = shares.reduce((sum, val) => sum.add(val.ugov), BigNumber.from(0));

  const poolPercentage = totalShares.isZero() ? 0 : formatEther(totalUserShares.mul(ethers.utils.parseEther("100")).div(totalShares));
  // cspell: disable-next-line
  const filteredShares = shares.filter(({ bond: { lpAmount }, ugov }) => lpAmount.gt(0) || ugov.gt(0));

  return (
    <div>
      <DepositShare onStake={onStake} disabled={processing.length > 0} maxLp={walletLpBalance} />
      <table id="Staking">
        <thead>
          <tr>
            <th>Action</th>
            <th>Rewards</th>
            <th>Unlock Time</th>
            <th>Est. Deposit</th>
          </tr>
        </thead>
        {filteredShares.length > 0 ? (
          <tbody>
            {filteredShares.map((share) => (
              <BondingShareRow key={share.id} {...share} disabled={processing.includes(share.id)} onWithdrawLp={onWithdrawLp} onClaimUbq={onClaimUbq} />
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
              {/* cspell: disable-next-line */}
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

type BondingShareRowProps = ShareData & { disabled: boolean; onWithdrawLp: Actions["onWithdrawLp"]; onClaimUbq: Actions["onClaimUbq"] };
// cspell: disable-next-line
const BondingShareRow = ({ id, ugov, sharesBalance, bond, weeksLeft, disabled, onWithdrawLp, onClaimUbq }: BondingShareRowProps) => {
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
    <tr key={id} title={`Bonding Share ID: ${id.toString()}`}>
      <td>
        {weeksLeft <= 0 && bond.lpAmount.gt(0) ? (
          <button disabled={disabled} onClick={onClickWithdraw}>
            Claim &amp; Withdraw
          </button>
        ) : // cspell: disable-next-line
        ugov.gt(0) ? (
          <Button disabled={disabled} onClick={() => onClaimUbq(+id.toString())}>
            Claim reward
          </Button>
        ) : null}
      </td>
      <td>
        <div>
          {/* cspell: disable-next-line */}
          <Icon icon="ubq" /> <span>{formatEther(ugov)}</span>
        </div>
      </td>
      <td>{weeksLeft <= 0 ? "Ready" : <span>{weeksLeft}w</span>}</td>

      <td>${Math.round(usdAmount * 100) / 100}</td>
    </tr>
  );
};

export default withLoadedContext(BondingSharesExplorerContainer);
