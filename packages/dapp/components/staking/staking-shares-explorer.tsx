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
  governanceToken: BigNumber;
  stake: {
    minter: string;
    lpFirstDeposited: BigNumber;
    creationBlock: BigNumber;
    lpRewardCredit: BigNumber;
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
  onClaimGovernance: (id: number) => void;
  onStake: (payload: { amount: BigNumber; weeks: BigNumber }) => void;
};

const USD_TO_LP = 0.7460387929;
const LP_TO_USD = 1 / USD_TO_LP;

export const StakingSharesExplorerContainer = ({ protocolContracts, web3Provider, walletAddress, signer }: LoadedContext) => {
  const [model, setModel] = useState<Model | null>(null);
  const [, doTransaction] = useTransactionLogger();
  const [, refreshBalances] = useBalances();

  useAsyncInit(fetchSharesInformation);
  async function fetchSharesInformation(processedShareId?: ShareData["id"]) {
    // cspell: disable-next-line
    const { stakingFacet, chefFacet, stakingShare: stakingToken, curveMetaPoolDollarTriPoolLp } = await protocolContracts;
    if (stakingFacet) {
      console.time("StakingShareExplorerContainer contract loading");
      const currentBlock = await web3Provider.getBlockNumber();
      // cspell: disable-next-line
      const blockCountInAWeek = +(await stakingFacet.blockCountInAWeek()).toString();
      const totalShares = await chefFacet?.totalShares();
      // cspell: disable-next-line
      const stakingShareIds = await stakingToken?.holderTokens(walletAddress);

      const walletLpBalance = await curveMetaPoolDollarTriPoolLp?.balanceOf(walletAddress);

      const shares: ShareData[] = [];
      await Promise.all(
        // cspell: disable-next-line
        stakingShareIds.map(async (id: BigNumber) => {
          // cspell: disable-next-line
          const [governanceToken, stake, stakingShareInfo, tokenBalance] = await Promise.all([
            // cspell: disable-next-line
            chefFacet?.pendingGovernance(id),
            // cspell: disable-next-line
            stakingToken?.getStake(id),
            chefFacet?.getStakingShareInfo(id),
            // cspell: disable-next-line
            stakingToken?.balanceOf(walletAddress, id),
          ]);

          const endBlock = +stake.endBlock.toString();
          const blocksLeft = endBlock - currentBlock;
          const weeksLeft = Math.round((blocksLeft / blockCountInAWeek) * 100) / 100;

          // If this is 0 it means the share ERC1155 token was transferred to another account
          if (+tokenBalance.toString() > 0) {
            // cspell: disable-next-line
            shares.push({ id: +id.toString(), governanceToken, stake, sharesBalance: stakingShareInfo[0], weeksLeft });
          }
        })
      );

      const sortedShares = shares.sort((a, b) => a.id - b.id);

      console.timeEnd("StakingShareExplorerContainer contract loading");
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
    const lpAmount = model.shares.find((s) => s.id === id)?.stake?.lpAmount;
    if (!lpAmount) throw new Error("Could not find share in model");
    return lpAmount;
  }

  const actions: Actions = {
    onWithdrawLp: useCallback(
      async ({ id, amount }) => {
        const { stakingFacet: staking, stakingShare: stakingToken } = await protocolContracts;
        if (!model || model.processing.includes(id)) return;
        console.log(`Withdrawing ${amount ? amount : "ALL"} LP from ${id}`);
        setModel((prevModel) => (prevModel ? { ...prevModel, processing: [...prevModel.processing, id] } : null));
        doTransaction("Withdrawing LP...", async () => {
          try {
            // cspell: disable-next-line
            const isAllowed = await stakingToken?.isApprovedForAll(walletAddress, staking?.address);
            if (!isAllowed) {
              // cspell: disable-next-line
              // Allow staking contract to control account share
              // cspell: disable-next-line
              if (!(await performTransaction(stakingToken?.connect(signer).setApprovalForAll(staking?.address, true)))) {
                return; // TODO: Show transaction errors to user
              }
            }

            const bigNumberAmount = amount ? ethers.utils.parseEther(amount.toString()) : allLpAmount(id);
            // cspell: disable-next-line
            await performTransaction(staking?.connect(signer).removeLiquidity(bigNumberAmount, BigNumber.from(id)));
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

    onClaimGovernance: useCallback(
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
        const { stakingFacet: staking, curveMetaPoolDollarTriPoolLp } = await protocolContracts;
        if (!model || model.processing.length) return;
        console.log(`Staking ${amount} for ${weeks} weeks`);
        doTransaction("Staking...", async () => {});

        // cspell: disable-next-line
        const allowance = await curveMetaPoolDollarTriPoolLp?.allowance(walletAddress, staking?.address);
        console.log("allowance", ethers.utils.formatEther(allowance));
        console.log("lpsAmount", ethers.utils.formatEther(amount));
        if (allowance.lt(amount)) {
          // cspell: disable-next-line
          await performTransaction(curveMetaPoolDollarTriPoolLp?.connect(signer).approve(staking?.address, amount));
          // cspell: disable-next-line
          const allowance2 = await curveMetaPoolDollarTriPoolLp?.allowance(walletAddress, staking?.address);
          console.log("allowance2", ethers.utils.formatEther(allowance2));
        }
        // cspell: disable-next-line
        await performTransaction(staking?.connect(signer).deposit(amount, weeks));

        fetchSharesInformation();
        refreshBalances();
      },
      [model]
    ),
  };

  return <StakingSharesExplorer model={model} actions={actions} />;
};

export const StakingSharesExplorer = memo(({ model, actions }: { model: Model | null; actions: Actions }) => {
  return <>{model ? <StakingSharesInformation {...model} {...actions} /> : <Loading text="Loading existing shares information" />}</>;
});

export const StakingSharesInformation = ({ shares, totalShares, onWithdrawLp, onClaimGovernance, onStake, processing, walletLpBalance }: Model & Actions) => {
  const totalUserShares = shares.reduce((sum, val) => {
    return sum.add(val.sharesBalance);
  }, BigNumber.from(0));

  const totalLpBalance = shares.reduce((sum, val) => {
    return sum.add(val.stake.lpAmount);
  }, BigNumber.from(0));
  // cspell: disable-next-line
  const totalPendingGovernanceToken = shares.reduce((sum, val) => sum.add(val.governanceToken), BigNumber.from(0));

  const poolPercentage = totalShares.isZero() ? 0 : formatEther(totalUserShares.mul(ethers.utils.parseEther("100")).div(totalShares));
  // cspell: disable-next-line
  const filteredShares = shares.filter(({ stake: { lpAmount }, governanceToken }) => lpAmount.gt(0) || governanceToken.gt(0));

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
              <StakingShareRow
                key={share.id}
                {...share}
                disabled={processing.includes(share.id)}
                onWithdrawLp={onWithdrawLp}
                onClaimGovernance={onClaimGovernance}
              />
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
              <Icon icon="governance" />
            </td>
            <td>
              {/* cspell: disable-next-line */}
              <span>{formatEther(totalPendingGovernanceToken)} </span>
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

type StakingShareRowProps = ShareData & { disabled: boolean; onWithdrawLp: Actions["onWithdrawLp"]; onClaimGovernance: Actions["onClaimGovernance"] };
// cspell: disable-next-line
const StakingShareRow = ({ id, governanceToken, stake, weeksLeft, disabled, onWithdrawLp, onClaimGovernance }: StakingShareRowProps) => {
  const [withdrawAmount] = useState("");

  const numLpAmount = +formatEther(stake.lpAmount);
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
    <tr key={id} title={`Staking Share ID: ${id.toString()}`}>
      <td>
        {weeksLeft <= 0 && stake.lpAmount.gt(0) ? (
          <button disabled={disabled} onClick={onClickWithdraw}>
            Claim &amp; Withdraw
          </button>
        ) : // cspell: disable-next-line
        governanceToken.gt(0) ? (
          <Button disabled={disabled} onClick={() => onClaimGovernance(+id.toString())}>
            Claim reward
          </Button>
        ) : null}
      </td>
      <td>
        <div>
          {/* cspell: disable-next-line */}
          <Icon icon="governance" /> <span>{formatEther(governanceToken)}</span>
        </div>
      </td>
      <td>{weeksLeft <= 0 ? "Ready" : <span>{weeksLeft}w</span>}</td>

      <td>${Math.round(usdAmount * 100) / 100}</td>
    </tr>
  );
};

export default withLoadedContext(StakingSharesExplorerContainer);
