import ICurveFactory from "@ubiquity/contracts/out/ICurveFactory.sol/ICurveFactory.json";
import IJar from "@ubiquity/contracts/out/IJar.sol/IJar.json";
import IMetaPool from "@ubiquity/contracts/out/IMetaPool.sol/IMetaPool.json";
import { ethers } from "ethers";
import { ICurveFactoryInterface } from "types/ICurveFactory";
import { IJarInterface } from "types/IJar";
import { IMetaPoolInterface } from "types/IMetaPool";
// import { UniswapV2PairABIInterface } from "types/UniswapV2PairABI";
// import { UniswapV3PoolABIInterface } from "types/UniswapV3PoolABI";
// import { UniswapV3RouterABIInterface } from "types/UniswapV3RouterABI";
// import { YieldProxyABIInterface } from "types/YieldProxyABI";
// import UniswapV2PairABI from "../config/abis/UniswapV2Pair.json";
// import UniswapV3PoolABI from "../config/abis/UniswapV3Pool.json";
// import UniswapV3RouterABI from "../config/abis/UniswapV3Router.json";
// import YieldProxyABI from "../config/abis/YieldProxy.json";
import { getContract } from "./contracts";

// // // //
// import { ChainlinkPriceFeedABIInterface } from "types/ChainlinkPriceFeedABI";
// import { DAITokenABIInterface } from "types/DAITokenABI";
// import { ERC20ABIInterface } from "types/ERC20ABI";
// import { USDCTokenABIInterface } from "types/USDCTokenABI";
// import { USDTTokenABIInterface } from "types/USDTTokenABI";

// // // //

// export const getUniswapV3RouterABIContract = (address: string, provider: ethers.providers.Provider) =>
//   getContract(UniswapV3RouterABI, address, provider) as UniswapV3RouterABIInterface; // UniswapV3RouterABI
// export const getChainlinkPriceFeedABIContract = (address: string, provider: ethers.providers.Provider) =>
// getContract(ChainlinkPriceFeedABI, address, provider) as ChainlinkPriceFeedABIInterface; // ChainlinkPriceFeedABI
// export const getERC20ABIContract = (address: string, provider: ethers.providers.Provider) => getContract(ERC20ABI, address, provider) as ERC20ABIInterface; // ERC20ABI
// export const getUSDCTokenABIContract = (address: string, provider: ethers.providers.Provider) =>
//   getContract(USDCTokenABI, address, provider) as USDCTokenABIInterface; // USDCTokenABI
// export const getDAITokenABIContract = (address: string, provider: ethers.providers.Provider) =>
//   getContract(DAITokenABI, address, provider) as DAITokenABIInterface; // DAITokenABI
// export const getUSDTTokenABIContract = (address: string, provider: ethers.providers.Provider) =>
//   getContract(USDTTokenABI, address, provider) as USDTTokenABIInterface; // USDTTokenABI
// export const getYieldProxyABIContract = (address: string, provider: ethers.providers.Provider) =>
//   getContract(YieldProxyABI, address, provider) as YieldProxyABIInterface; // YieldProxyABI

// // // //
export const getDollar3poolMarketContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(IMetaPool.abi, address, provider) as IMetaPoolInterface; // IMetaPool

// export const getUniswapV2PairABIContract = (address: string, provider: ethers.providers.Provider) =>
//   getContract(UniswapV2PairABI, address, provider) as UniswapV2PairABIInterface; // UniswapV2PairABI

// export const getUniswapV3PoolContract = (address: string, provider: ethers.providers.Provider) =>
//   getContract(UniswapV3PoolABI, address, provider) as UniswapV3PoolABIInterface; // UniswapV3PoolABI

// export const getUniswapV3RouterContract = (address: string, provider: ethers.providers.Provider) =>
//   getContract(UniswapV3RouterABI, address, provider) as UniswapV3RouterABIInterface; // UniswapV3RouterABI

export const getCurveFactoryContract = (address: string, provider: ethers.providers.Provider) =>
  getContract(ICurveFactory.abi, address, provider) as ICurveFactoryInterface; // ICurveFactory

export const getIJarContract = (address: string, provider: ethers.providers.Provider) => getContract(IJar.abi, address, provider) as IJarInterface; // IJar

// export const getYieldProxyContract = (address: string, provider: ethers.providers.Provider) =>
//   getContract(YieldProxyABI, address, provider) as YieldProxyABIInterface; // YieldProxyABI
