import { ethers } from "ethers";
import { useEffect, useState } from "react";

import { ERC20 } from "@/dollar-types";

import { goldenPool, PoolData } from "../pools";
import { Contracts } from "./useLaunchPartyContracts";

const usePrices = (contracts: Contracts | null, tokensContracts: ERC20[], poolsData: { [token: string]: PoolData }) => {
  const [uarUsdPrice, setUarUsdPrice] = useState<number | null>(null);

  async function refreshPrices() {
    if (!contracts || !tokensContracts || !poolsData) return;

    const goldenPoolData = poolsData[goldenPool.tokenAddress];

    if (!goldenPoolData || !goldenPoolData.liquidity1 || !goldenPoolData.liquidity2) return;

    // Assuming golden pool is uCR-ETH
    // Example: If we have 5 uCR and 100 ETH in the pool, then we take 1 uCR = 20 ETH

    const uarEthPrice = goldenPoolData.liquidity2 / goldenPoolData.liquidity1;

    const [, price] = await contracts.chainLink.latestRoundData();
    const ethUsdPrice = +ethers.utils.formatUnits(price, "wei") / 1e8;

    console.log("ETH-USD", ethUsdPrice);
    setUarUsdPrice(ethUsdPrice * uarEthPrice);
  }
  useEffect(() => {
    refreshPrices();
  }, [contracts, tokensContracts, poolsData]);

  return { uarUsdPrice, refreshPrices };
};

export default usePrices;
