import { ethers } from "ethers";
import { ERC20 } from "../../../contracts/artifacts/types";

export type PoolInfo = {
  name: string;
  poolAddress: string;
  tokenAddress: string;
  // If poolAddress === tokenAddress
  //   pool and token are is UniswapV2
  // else
  //   pool is UniswapV3 and token is Gelato
  logo: string | null;
};

export type UnipoolData = {
  poolAddress: string;
  contract1: ERC20;
  contract2: ERC20;
  token1: string;
  token2: string;
  decimal1: number;
  decimal2: number;
  balance1: ethers.BigNumber;
  balance2: ethers.BigNumber;
  symbol1: string;
  symbol2: string;
  name1: string;
  name2: string;
};

export type PoolData = {
  token1: string;
  token2: string;
  symbol1: string;
  symbol2: string;
  name1: string;
  name2: string;
  liquidity1: number | null;
  liquidity2: number | null;
  poolTokenBalance: number;
  decimals: number;
  apy: number;
};

export const pools: PoolInfo[] = [
  "uAD-LUSD",
  "uAD-OHM",
  "uAD-MIM",
  "uAD-UST",
  "uAD-FRAX",
  "uAD-FEI",
  "uAD-DOLA",
  "uAD-DAI",
  "uAD-USDC",
  "uAD-USDT",
  "uAD-ALUSD",
].map((name) => ({
  name,
  poolAddress: "0x681b4c3af785dacaccc496b9ff04f9c31bce4090",
  tokenAddress: "0xA9514190cBBaD624c313Ea387a18Fd1dea576cbd",
  logo: `/tokens-icons/${name.split("-")[1].toLowerCase()}.png`,
}));

export const poolByAddress = (address: string) => pools.find((p) => p.tokenAddress === address) || (address === goldenPool.tokenAddress ? goldenPool : null);

export const goldenPool: PoolInfo = {
  name: "uAR-WETH",
  poolAddress: "0xd9dc4a753e58cd7a8b03360f042b004da3eb178a",
  tokenAddress: "0xd9dc4a753e58cd7a8b03360f042b004da3eb178a",
  logo: null,
};

export const allPools = pools.concat([goldenPool]);
export const poolsByToken: { [token: string]: PoolInfo } = allPools.reduce((acc, pool) => ({ ...acc, [pool.tokenAddress]: pool }), {});
