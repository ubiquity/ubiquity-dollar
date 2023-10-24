import { BigNumber, ethers } from "ethers";

export interface EthAccount {
  balance: number;
  address: string;
}

export interface Transaction {
  id: string;
  active: boolean;
  title?: string;
}

export interface PoolImmutables {
  factory: string;
  token0: string;
  token1: string;
  fee: number;
  tickSpacing: number;
  maxLiquidityPerTick: ethers.BigNumber;
}

export interface PoolState {
  liquidity: ethers.BigNumber;
  sqrtPriceX96: ethers.BigNumber;
  tick: number;
  observationIndex: number;
  observationCardinality: number;
  observationCardinalityNext: number;
  feeProtocol: number;
  unlocked: boolean;
}

export interface Balances {
  dollar: BigNumber;
  _3crv: BigNumber;
  dollar3crv: BigNumber;
  credit: BigNumber;
  creditNft: BigNumber;
  governance: BigNumber;
  stakingShares: BigNumber;
  usdc: BigNumber;
  dai: BigNumber;
  usdt: BigNumber;
}
