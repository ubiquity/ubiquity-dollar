import { ethers } from "ethers";
import { ERC20 } from "../../../contracts/artifacts/types";

export type PoolInfo = {
  name: string;
  uniV3PoolAddress: string;
  tokenAddress: string;
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
  // {
  //   token1: "UBQ",
  //   token2: "uAD",
  //   poolMarketLink: "https://app.uniswap.org",
  //   tokenAddress: "0x4e38D89362f7e5db0096CE44ebD021c3962aA9a0",
  //   logo: "ubq.png",
  // },
  // {
  //   token1: "uAD",
  //   token2: "uAD",
  //   poolMarketLink: "https://app.uniswap.org",
  //   tokenAddress: "0x0F644658510c95CB46955e55D7BA9DDa9E9fBEc6",
  //   logo: "ubq.png",
  // },
  // {
  //   token1: "DAI",
  //   token2: "uAD",
  //   poolMarketLink: "https://app.uniswap.org",
  //   tokenAddress: "0x6b175474e89094c44da98b954eedeac495271d0f",
  //   logo: "dai.png",
  // },
  {
    name: "uAD-USDC",
    uniV3PoolAddress: "0x681b4c3af785dacaccc496b9ff04f9c31bce4090",
    tokenAddress: "0xA9514190cBBaD624c313Ea387a18Fd1dea576cbd",
    logo: "usdc.png",
  },
];

export const poolByAddress = (address: string) => pools.find((p) => p.tokenAddress === address) || (address === goldenPool.tokenAddress ? goldenPool : null);

export const goldenPool: PoolInfo = {
  name: "uAR-uAD",
  uniV3PoolAddress: "0x681b4c3af785dacaccc496b9ff04f9c31bce4090",
  tokenAddress: "0xA9514190cBBaD624c313Ea387a18Fd1dea576cbd",
  logo: null,
};

export const allPools = pools.concat([goldenPool]);
export const poolsByToken: { [token: string]: PoolInfo } = allPools.reduce((acc, pool) => ({ ...acc, [pool.tokenAddress]: pool }), {});
