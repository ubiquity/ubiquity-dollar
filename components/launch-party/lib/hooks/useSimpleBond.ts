import { ethers } from "ethers";
import { useEffect, useState } from "react";

import { ERC20 } from "@/dollar-types";
import { useManagerManaged, useWeb3 } from "@/lib/hooks";
import { ZERO_ADDRESS } from "@/lib/utils";

import fetchUniswapPoolsData from "../fetchUniswapPoolsData";
import { allPools, PoolData, poolsByToken } from "../pools";
import { apyFromRatio, multiplierFromRatio } from "../utils";
import { Contracts } from "./useLaunchPartyContracts";

export type BondData = {
  tokenName: string;
  claimed: number;
  rewards: number;
  claimable: number;
  depositAmount: number;
  endsAtBlock: number;
  endsAtDate: Date;
  rewardPrice: number;
};

const useSimpleBond = (contracts: Contracts | null, tokensContracts: ERC20[]) => {
  const [{ provider, walletAddress }] = useWeb3();
  const ubqContracts = useManagerManaged();

  const [rewardTokenBalance, setRewardTokenBalance] = useState<number | null>(null);
  const [tokensRatios, setTokensRatios] = useState<{ [token: string]: ethers.BigNumber }>({});
  const [poolsData, setPoolsData] = useState<{ [token: string]: PoolData }>({});
  const [bondsData, setBondsData] = useState<BondData[] | null>(null);
  const [needsStick, setNeedsStick] = useState<boolean>(true);

  async function refreshSimpleBondData() {
    if (provider && walletAddress && contracts && tokensContracts.length > 0 && ubqContracts) {
      const blocksCountInAWeek = (await ubqContracts.bonding.blockCountInAWeek()).toNumber();
      const vestingBlocks = (await contracts.simpleBond.vestingBlocks()).toNumber();

      const ratios = await Promise.all(allPools.map((pool) => contracts.simpleBond.rewardsRatio(pool.tokenAddress)));

      const newTokensRatios = Object.fromEntries(allPools.map((pool, i) => [pool.tokenAddress, ratios[i]]));

      const newUnipoolFullData = await fetchUniswapPoolsData(
        allPools.map(({ poolAddress, tokenAddress }) => ({ address: poolAddress, version: poolAddress === tokenAddress ? "v2" : "v3" })),
        provider
      );

      const newPoolsData: { [token: string]: PoolData } = (
        await Promise.all(
          tokensContracts.map((tokenContract) =>
            Promise.all([tokenContract.address, tokenContract.balanceOf(walletAddress), tokenContract.decimals(), newTokensRatios[tokenContract.address]])
          )
        )
      ).reduce<{ [token: string]: PoolData }>((acc, [address, balance, decimals, reward]) => {
        const poolTokenBalance = +ethers.utils.formatUnits(balance, decimals);

        const multiplier = multiplierFromRatio(reward);
        const apy = apyFromRatio(reward);

        const uniPoolData = newUnipoolFullData[poolsByToken[address].poolAddress];
        const liquidity1 = +ethers.utils.formatUnits(uniPoolData.balance1, uniPoolData.decimal1);
        const liquidity2 = +ethers.utils.formatUnits(uniPoolData.balance2, uniPoolData.decimal2);

        acc[address] = {
          poolTokenBalance,
          apy,
          token1: uniPoolData.token1,
          token2: uniPoolData.token2,
          liquidity1,
          liquidity2,
          symbol1: uniPoolData.symbol1,
          symbol2: uniPoolData.symbol2,
          name1: uniPoolData.name1,
          name2: uniPoolData.name2,
          decimals,
          multiplier,
        };

        return acc;
      }, {});

      // Get the current bonds data

      const currentBlock = await provider.getBlockNumber();
      const bondsCount = (await contracts.simpleBond.bondsCount(walletAddress)).toNumber();

      const newBondsData: BondData[] = (
        await Promise.all(
          Array(bondsCount)
            .fill(null)
            .map(async (_, i) => ({
              bond: await contracts.simpleBond.bonds(walletAddress, i),
              rewards: await contracts.simpleBond.rewardsBondOf(walletAddress, i),
            }))
        )
      ).map(({ bond: { token, amount, rewards, claimed, block }, rewards: { rewardsClaimable } }) => {
        const pool = poolsByToken[token];
        const decimals = newPoolsData[token]?.decimals;
        if (!pool || !decimals) console.error("No pool found for token", token);
        return {
          tokenName: pool.name,
          claimed: +ethers.utils.formatUnits(claimed, decimals),
          claimable: +ethers.utils.formatUnits(rewardsClaimable, decimals),
          rewards: +ethers.utils.formatUnits(rewards, decimals),
          depositAmount: +ethers.utils.formatUnits(amount, decimals),
          endsAtBlock: block.toNumber() + vestingBlocks,
          endsAtDate: new Date(+new Date() + ((block.toNumber() + vestingBlocks - currentBlock) / blocksCountInAWeek) * 7 * 24 * 60 * 60 * 1000),
          rewardPrice: 1, // TODO: Get price for each LP contract
        };
      });

      // Get the balance of the reward token

      const newRewardTokenBalance = +ethers.utils.formatUnits(await contracts.rewardToken.balanceOf(walletAddress), await contracts.rewardToken.decimals());

      // Get wether the Ubiquistick is still neccesary

      setNeedsStick((await contracts.simpleBond.sticker()) !== ZERO_ADDRESS);

      // Set all the states

      setTokensRatios(newTokensRatios);
      setPoolsData(newPoolsData);
      setBondsData(newBondsData);
      setRewardTokenBalance(newRewardTokenBalance);
    }
  }

  useEffect(() => {
    refreshSimpleBondData();
  }, [provider, walletAddress, contracts, tokensContracts.length, ubqContracts]);

  return { rewardTokenBalance, tokensRatios, poolsData, bondsData, needsStick, refreshSimpleBondData };
};

export default useSimpleBond;
