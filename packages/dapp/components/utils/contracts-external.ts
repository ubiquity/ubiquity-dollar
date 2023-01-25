import ICurveFactory from "@ubiquity/contracts/out/ICurveFactory.sol/ICurveFactory.json";
import IJar from "@ubiquity/contracts/out/IJar.sol/IJar.json";
// import IMetaPool from "@ubiquity/contracts/out/IMetaPool.sol/IMetaPool.json";
import { Contract, ethers } from "ethers";
import { ICurveFactory as IICurveFactory } from "types/ICurveFactory";
import { IJar as IIJar } from "types/IJar";

import IMetaPool from "@ubiquity/contracts/out/IMetaPool.sol/IMetaPool.json";
import { IMetaPool as IIMetaPool } from "types/IMetaPool";

import { getContract } from "./contracts";

// // // //
// import { ChainlinkPriceFeedABI as IChainlinkPriceFeedABI } from "types/ChainlinkPriceFeedABI";

// import { ERC20ABI as IERC20ABI } from "types/ERC20ABI";

// // // //

// export const getChainlinkPriceFeedABIContract = (address: string, provider: ethers.providers.Provider) =>
// getContract(ChainlinkPriceFeedABI, address, provider) as IChainlinkPriceFeedABI["functions"] // ChainlinkPriceFeedABI
// export const getERC20ABIContract = (address: string, provider: ethers.providers.Provider) => getContract(ERC20ABI, address, provider) as IERC20ABI["functions"] // ERC20ABI

// // // //
export const getDollar3poolMarketContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(IMetaPool.abi, address, provider) as IIMetaPool; // IMetaPool

export const getCurveFactoryContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ICurveFactory.abi, address, provider) as IICurveFactory; // ICurveFactory

export const getIJarContract = (address: string, provider: ethers.providers.Provider) => getContract(IJar.abi, address, provider) as IIJar; // IJar

// UNISWAP

import UniswapV2PairABI from "../config/abis/UniswapV2Pair.json";
import UniswapV3PoolABI from "../config/abis/UniswapV3Pool.json";
import UniswapV3RouterABI from "../config/abis/UniswapV3Router.json";

export const getUniswapV2PairABIContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(UniswapV2PairABI, address, provider) as Contract; // UniswapV2PairABI
export const getUniswapV3PoolContract = (address: string, provider: ethers.providers.Provider) => getContract(UniswapV3PoolABI, address, provider) as Contract; // UniswapV3PoolABI
export const getUniswapV3RouterContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(UniswapV3RouterABI, address, provider) as Contract; // UniswapV3RouterABI
