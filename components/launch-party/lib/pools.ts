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
  multiplier: number;
  apy: number | null;
};

type FungiblePoolContract = "Arrakis" | "UniswapV2";

export const getPoolContract = (pool: PoolInfo): FungiblePoolContract => {
  return pool.poolAddress === pool.tokenAddress ? "UniswapV2" : "Arrakis";
};

export const getPoolUrl = (poolInfo: PoolInfo, poolData: PoolData): string => {
  return {
    UniswapV2: `https://app.uniswap.org/#/add/v2/${poolData.token1}/${poolData.token2}`,
    Arrakis: `https://beta.arrakis.finance/#/vaults/${poolInfo.tokenAddress}`,
  }[getPoolContract(poolInfo)];
};

export const goldenPool: PoolInfo = {
  name: "uCR-WETH",
  poolAddress: "0xd9dc4a753e58cd7a8b03360f042b004da3eb178a",
  tokenAddress: "0xd9dc4a753e58cd7a8b03360f042b004da3eb178a",
  logo: null,
};

export const pools: PoolInfo[] = [
  {
    name: "uAD-ETH",
    poolAddress: "0x95e3547d5a326092661f16ec06e6fc5681c8d33c",
    tokenAddress: "0x95e3547d5a326092661f16ec06e6fc5681c8d33c",
    logo: "/tokens-icons/eth.png",
  },
  {
    name: "uAD-LUSD",
    poolAddress: "0xb065c77afc6e1a03b6166ac0fb2f4e84ff6a24d4",
    tokenAddress: "0x8824e0cd99f5c1eef50c8602987af364096625db",
    logo: "/tokens-icons/lusd.png",
  },
  {
    name: "uAD-DAI",
    poolAddress: "0xdae886e2c774c0773f2497a3e1dac44e10a13dbc",
    tokenAddress: "0xe8c94b3c4ec695f811328a5c3cf9afd477e1294b",
    logo: "/tokens-icons/dai.png",
  },
  {
    name: "uAD-USDC",
    poolAddress: "0x681b4c3af785dacaccc496b9ff04f9c31bce4090",
    tokenAddress: "0xA9514190cBBaD624c313Ea387a18Fd1dea576cbd",
    logo: "/tokens-icons/usdc.png",
  },
];

/** Other possible tokens we could add:
 * uAD-OHM
 * uAD-MIM
 * uAD-UST
 * uAD-FRAX
 * uAD-FEI
 * uAD-DOLA
 * uAD-USDT
 * uAD-ALUSD
 */

export const poolByAddress = (address: string) => pools.find((p) => p.tokenAddress === address) || (address === goldenPool.tokenAddress ? goldenPool : null);

export const allPools = pools.concat([goldenPool]);
export const poolsByToken: { [token: string]: PoolInfo } = allPools.reduce((acc, pool) => ({ ...acc, [pool.tokenAddress]: pool }), {});
