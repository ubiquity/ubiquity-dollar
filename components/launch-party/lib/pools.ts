export type PoolInfo = {
  token1: string;
  token2: string;
  poolMarketLink: string;
  tokenAddress: string;
  logo: string | null;
};

export type PoolData = {
  liquidity1: number;
  liquidity2: number;
  poolTokenBalance: number;
  apy: number;
};

export const pools: PoolInfo[] = [
  {
    token1: "UBQ",
    token2: "uAD",
    poolMarketLink: "https://app.uniswap.org",
    tokenAddress: "0x4e38D89362f7e5db0096CE44ebD021c3962aA9a0",
    logo: "ubq.png",
  },
  {
    token1: "uAD",
    token2: "uAD",
    poolMarketLink: "https://app.uniswap.org",
    tokenAddress: "0x0F644658510c95CB46955e55D7BA9DDa9E9fBEc6",
    logo: "ubq.png",
  },
  {
    token1: "DAI",
    token2: "uAD",
    poolMarketLink: "https://app.uniswap.org",
    tokenAddress: "0x0000000000000000000000000000000000000000",
    logo: "dai.png",
  },
  {
    token1: "USDC",
    token2: "uAD",
    poolMarketLink: "https://app.uniswap.org",
    tokenAddress: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
    logo: "usdc.png",
  },
];

export const poolByAddress = (address: string) => pools.find((p) => p.tokenAddress === address);

export const goldenPool: PoolInfo = {
  token1: "uAR",
  token2: "ETH",
  poolMarketLink: "https://app.uniswap.org",
  tokenAddress: "0x0000000000000000000000000000000000000000",
  logo: null,
};

const mockPoolData: { [key: string]: PoolData } = {
  "UBQ-uAD": { liquidity1: 2000, liquidity2: 3.5, poolTokenBalance: 2323, apy: 2000 },
  "uAD-uAD": { liquidity1: 2000, liquidity2: 3.5, poolTokenBalance: 2323, apy: 2000 },
  "DAI-uAD": { liquidity1: 2000, liquidity2: 3.5, poolTokenBalance: 2323, apy: 2000 },
  "USDC-uAD": { liquidity1: 2500, liquidity2: 4, poolTokenBalance: 0, apy: 1800 },
  "uAR-uAD": { liquidity1: 50000, liquidity2: 2.2, poolTokenBalance: 3002, apy: 54000 },
};

export const fetchPoolData = async (pool: PoolInfo): Promise<PoolData> => {
  return mockPoolData[pool.token1 + "-" + pool.token2];
};
