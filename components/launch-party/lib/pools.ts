export type PoolInfo = {
  token1: string;
  token2: string;
  poolMarketLink: string;
  tokenAddress: string;
  logo: string | null;
};

export type PoolData = {
  liquidity1: number | null;
  liquidity2: number | null;
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
    tokenAddress: "0x6b175474e89094c44da98b954eedeac495271d0f",
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

export const poolByAddress = (address: string) => pools.find((p) => p.tokenAddress === address) || (address === goldenPool.tokenAddress ? goldenPool : null);

export const goldenPool: PoolInfo = {
  token1: "uAR",
  token2: "uAD",
  poolMarketLink: "https://app.uniswap.org",
  tokenAddress: "0x5894cFEbFdEdBe61d01F20140f41c5c49AedAe97",
  logo: null,
};
