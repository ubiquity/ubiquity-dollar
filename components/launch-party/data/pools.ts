export type PoolInfo = {
  token1: string;
  token2: string;
  poolMarketLink: string;
  bondingContractAddress: string;
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
    token1: "DAI",
    token2: "ETH",
    poolMarketLink: "https://app.uniswap.org",
    bondingContractAddress: "0x0000000000000000000000000000000000000000",
    logo: "dai.png",
  },
  {
    token1: "USDC",
    token2: "ETH",
    poolMarketLink: "https://app.uniswap.org",
    bondingContractAddress: "0x0000000000000000000000000000000000000000",
    logo: "usdc.png",
  },
];

export const goldenPool: PoolInfo = {
  token1: "uAR",
  token2: "ETH",
  poolMarketLink: "https://app.uniswap.org",
  bondingContractAddress: "0x0000000000000000000000000000000000000000",
  logo: null,
};

const mockPoolData: { [key: string]: PoolData } = {
  "DAI-ETH": { liquidity1: 2000, liquidity2: 3.5, poolTokenBalance: 2323, apy: 2000 },
  "USDC-ETH": { liquidity1: 2500, liquidity2: 4, poolTokenBalance: 0, apy: 1800 },
  "uAR-ETH": { liquidity1: 50000, liquidity2: 2.2, poolTokenBalance: 3002, apy: 54000 },
};

export const fetchPoolData = async (pool: PoolInfo): Promise<PoolData> => {
  return mockPoolData[pool.token1 + "-" + pool.token2];
};
