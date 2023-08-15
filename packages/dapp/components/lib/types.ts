import { ethers } from "ethers";

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
  uad: ethers.BigNumber;
  _3crv: ethers.BigNumber;
  uad3crv: ethers.BigNumber;
  ucr: ethers.BigNumber;
  ucrNft: ethers.BigNumber;
  ubq: ethers.BigNumber;
  stakingShares: ethers.BigNumber;
  usdc: ethers.BigNumber;
  dai: ethers.BigNumber;
  usdt: ethers.BigNumber;
}