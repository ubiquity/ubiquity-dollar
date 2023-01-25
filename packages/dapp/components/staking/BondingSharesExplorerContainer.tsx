import { BigNumber, ethers } from "ethers";
import { useCallback, useState } from "react";
import { performTransaction, useAsyncInit } from "@/lib/utils";
import { LoadedContext } from "@/lib/withLoadedContext";
import useBalances from "../lib/hooks/useBalances";
import useTransactionLogger from "../lib/hooks/useTransactionLogger";
import { Model, ShareData, Actions, BondingSharesExplorer } from "./BondingSharesExplorer";

export function BondingSharesExplorerContainer({ managedContracts, web3Provider, walletAddress, signer }: LoadedContext) {
  const [model, setModel] = useState<Model | null>(null);
  const [, doTransaction] = useTransactionLogger();
  const [, refreshBalances] = useBalances();

  const { staking: bonding, ubiquityChef: ubiquityChef, stakingToken: stakingToken, dollarMetapool: metaPool } = managedContracts;

  useAsyncInit(fetchStakesInformation);

  async function fetchStakesInformation(stakeId?: ShareData["id"]) {
    console.time("BondingShareExplorerContainer contract loading");
    const currentBlock = await web3Provider.getBlockNumber();
    const blockCountInAWeek = +(await bonding.blockCountInAWeek()).toString();
    const totalShares = await ubiquityChef.totalShares();
    const stakedPositionIds = await stakingToken.holderTokens(walletAddress);
    const walletLpBalance = await metaPool.balanceOf(walletAddress);

    const shares: ShareData[] = [];

    const mapFunction = async (id: BigNumber) => {
      const [governanceToken, stake, stakingTokenInfo, stakingTokenBalance] = await Promise.all([
        ubiquityChef.pendingGovernance(id),
        stakingToken.getStake(id),
        ubiquityChef.getStakingTokenInfo(id),
        stakingToken.balanceOf(walletAddress, id),
      ]);

      const endBlock = +stake.endBlock.toString();
      const blocksLeft = endBlock - currentBlock;
      const weeksLeft = Math.round((blocksLeft / blockCountInAWeek) * 100) / 100;

      // If this is 0 it means the share ERC1155 token was transferred to another account
      if (+stakingTokenBalance.toString() > 0) {
        shares.push({ id: id, rewards: governanceToken, stake: stake, stakingTokenBalance: stakingTokenInfo[0], weeksLeft });
      }
    };

    // Argument of type
    // '(id: string) => Promise<void>'
    // is not assignable to parameter of type
    // '(value: BigNumber, index: number, array: BigNumber[]) => Promise<void>'
    // .
    // Types of parameters 'id' and 'value' are incompatible.
    //   Type 'BigNumber' is not assignable to type 'string'.ts(2345)
    await Promise.all(stakedPositionIds.map((id) => mapFunction(id)));

    // typecast BigNumber into Number so that I can compare the difference in values
    const sortedShares = shares.sort((a, b) => Number(a.id) - Number(b.id));

    console.timeEnd("BondingShareExplorerContainer contract loading");
    setModel((model) => ({
      processing: model ? model.processing.filter((id) => id !== stakeId) : [],
      shares: sortedShares,
      totalShares,
      walletLpBalance,
    }));
  }

  function allLpAmount(id: BigNumber) {
    if (!model) throw new Error("No model");
    const lpAmount = model.shares.find((s) => Number(s.id) === Number(id))?.stake?.lpAmount;
    if (!lpAmount) throw new Error("Could not find share in model");
    return lpAmount;
  }

  const actions: Actions = {
    onWithdrawLp: useCallback(
      async ({ id, amount }) => {
        if (!model || model.processing.includes(id)) return;
        console.log(`Withdrawing ${amount ? amount : "ALL"} LP from ${id}`);
        setModel((prevModel) => {
          if (!prevModel) return null;
          if (prevModel.processing.includes(id)) return prevModel;
          return { ...prevModel, processing: [...prevModel.processing, id] };
        });
        doTransaction("Withdrawing LP...", async () => {
          try {
            const isAllowed = await stakingToken.isApprovedForAll(walletAddress, bonding.address);
            if (!isAllowed) {
              // Allow bonding contract to control account share
              if (!(await performTransaction(stakingToken.connect(signer).setApprovalForAll(bonding.address, true)))) {
                return; // TODO: Show transaction errors to user
              }
            }

            const bigNumberAmount = amount ? ethers.utils.parseEther(amount.toString()) : allLpAmount(id);
            await performTransaction(bonding.connect(signer).removeLiquidity(bigNumberAmount, BigNumber.from(id)));
          } catch (error) {
            console.log(`Withdrawing LP from ${id} failed:`, error);
            // throws exception to update the transaction log
            throw error;
          } finally {
            fetchStakesInformation(id);
            refreshBalances();
          }
        });
      },
      [model]
    ),

    onClaimUbq: useCallback(
      async (id) => {
        if (!model) return;
        console.log(`Claiming Ubiquity Governance token rewards from ${id}`);
        setModel((prevModel) => (prevModel ? { ...prevModel, processing: [...prevModel.processing, id] } : null));
        doTransaction("Claiming Ubiquity Governance tokens...", async () => {
          try {
            await performTransaction(ubiquityChef.connect(signer).getRewards(BigNumber.from(id)));
          } catch (error) {
            console.log(`Claiming Ubiquity Governance token rewards from ${id} failed:`, error);
            // throws exception to update the transaction log
            throw error;
          } finally {
            fetchStakesInformation(id);
            refreshBalances();
          }
        });
      },
      [model]
    ),

    onStake: useCallback(
      async ({ amount, weeks }) => {
        if (!model || model.processing.length) return;
        console.log(`Staking ${amount} for ${weeks} weeks`);
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

        fetchStakesInformation();
        refreshBalances();
      },
      [model]
    ),
  };

  return <BondingSharesExplorer model={model} actions={actions} />;
}
