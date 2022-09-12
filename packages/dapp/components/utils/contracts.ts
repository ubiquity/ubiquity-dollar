import { ContractInterface, ethers } from "ethers";

import UniswapV2PairABI from "../config/abis/UniswapV2Pair.json";
import UniswapV3PoolABI from "../config/abis/UniswapV3Pool.json";
import ChainlinkPriceFeedABI from "../config/abis/ChainlinkPriceFeed.json";
import ERC20ABI from "../config/abis/ERC20.json";

import SimpleBond from "@ubiquity/ubiquistick/artifacts/contracts/SimpleBond.sol/SimpleBond.json";
import UbiquityStick from "@ubiquity/ubiquistick/artifacts/contracts/TheUbiquityStick.sol/TheUbiquityStick.json";
import UbiquityStickSale from "@ubiquity/ubiquistick/artifacts/contracts/TheUbiquityStickSale.sol/TheUbiquityStickSale.json";
import ERC1155Ubiquity from "@ubiquity/dollar/artifacts/contracts/ERC1155Ubiquity.sol/ERC1155Ubiquity.json";
import IJar from "@ubiquity/dollar/artifacts/contracts/interfaces/IJar.sol/IJar.json";
import DebtCouponManager from "@ubiquity/dollar/artifacts/contracts/DebtCouponManager.sol/DebtCouponManager.json";
import ICurveFactory from "@ubiquity/dollar/artifacts/contracts/interfaces/ICurveFactory.sol/ICurveFactory.json";
import YieldProxy from "@ubiquity/dollar/artifacts/contracts/YieldProxy.sol/YieldProxy.json";
import BondingShareV2 from "@ubiquity/dollar/artifacts/contracts/BondingShareV2.sol/BondingShareV2.json";
import BondingV2 from "@ubiquity/dollar/artifacts/contracts/BondingV2.sol/BondingV2.json";
import DebtCoupon from "@ubiquity/dollar/artifacts/contracts/DebtCoupon.sol/DebtCoupon.json";
import DollarMintingCalculator from "@ubiquity/dollar/artifacts/contracts/DollarMintingCalculator.sol/DollarMintingCalculator.json";
import ICouponsForDollarsCalculator from "@ubiquity/dollar/artifacts/contracts/interfaces/ICouponsForDollarsCalculator.sol/ICouponsForDollarsCalculator.json";
import IMetaPool from "@ubiquity/dollar/artifacts/contracts/interfaces/IMetaPool.sol/IMetaPool.json";
import IUARForDollarsCalculator from "@ubiquity/dollar/artifacts/contracts/interfaces/IUARForDollarsCalculator.sol/IUARForDollarsCalculator.json";
import MasterChefv2 from "@ubiquity/dollar/artifacts/contracts/MasterChefV2.sol/MasterChefV2.json";
import SushiSwapPool from "@ubiquity/dollar/artifacts/contracts/SushiSwapPool.sol/SushiSwapPool.json";
import TWAPOracle from "@ubiquity/dollar/artifacts/contracts/TWAPOracle.sol/TWAPOracle.json";
import UbiquityAlgorithmicDollarManager from "@ubiquity/dollar/artifacts/contracts/UbiquityAlgorithmicDollarManager.sol/UbiquityAlgorithmicDollarManager.json";
import UbiquityAlgorithmicDollar from "@ubiquity/dollar/artifacts/contracts/UbiquityAlgorithmicDollar.sol/UbiquityAlgorithmicDollar.json";
import UbiquityAutoRedeem from "@ubiquity/dollar/artifacts/contracts/UbiquityAutoRedeem.sol/UbiquityAutoRedeem.json";
import UbiquityFormulas from "@ubiquity/dollar/artifacts/contracts/UbiquityFormulas.sol/UbiquityFormulas.json";
import UbiquityGovernance from "@ubiquity/dollar/artifacts/contracts/UbiquityGovernance.sol/UbiquityGovernance.json";

const getContract = (abi: ContractInterface, address: string, provider: ethers.providers.Provider) => {
  return new ethers.Contract(address, abi, provider);
};

export const getUniswapV2FactoryContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(UniswapV2PairABI, address, provider);
};

export const getUniswapV3PoolContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(UniswapV3PoolABI, address, provider);
};

export const getChainlinkPriceFeedContract = (address: string, provider: ethers.providers.Provider): ethers.Contract => {
  return getContract(ChainlinkPriceFeedABI, address, provider);
};

export const getERC20Contract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(ERC20ABI, address, provider);
};

export const getERC1155UbiquityContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(ERC1155Ubiquity.abi, address, provider);
};

export const getSimpleBondContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(SimpleBond.abi, address, provider);
};

export const getUbiquitystickContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(UbiquityStick.abi, address, provider);
};

export const getUbiquityStickSaleContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(UbiquityStickSale.abi, address, provider);
};

export const getIJarContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(IJar.abi, address, provider);
};

export const getDebtCouponManagerContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(DebtCouponManager.abi, address, provider);
};

export const getCurveFactoryContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(ICurveFactory.abi, address, provider);
};

export const getYieldProxyContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(YieldProxy.abi, address, provider);
};

export const getBondingShareV2Contract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(BondingShareV2.abi, address, provider);
};

export const getBondingV2Contract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(BondingV2.abi, address, provider);
};

export const getDebtCouponContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(DebtCoupon.abi, address, provider);
};

export const getTWAPOracleContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(TWAPOracle.abi, address, provider);
};

export const getDollarMintingCalculatorContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(DollarMintingCalculator.abi, address, provider);
};

export const getICouponsForDollarsCalculatorContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(ICouponsForDollarsCalculator.abi, address, provider);
};

export const getIUARForDollarsCalculatorContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(IUARForDollarsCalculator.abi, address, provider);
};

export const getIMetaPoolContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(IMetaPool.abi, address, provider);
};

export const getMasterChefv2Contract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(MasterChefv2.abi, address, provider);
};

export const getSushiSwapPoolContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(SushiSwapPool.abi, address, provider);
};

export const getUbiquityAlgorithmicDollarManagerContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(UbiquityAlgorithmicDollarManager.abi, address, provider);
};

export const getUbiquityAlgorithmicDollarContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(UbiquityAlgorithmicDollar.abi, address, provider);
};

export const getUbiquityAutoRedeemContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(UbiquityAutoRedeem.abi, address, provider);
};

export const getUbiquityFormulasContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(UbiquityFormulas.abi, address, provider);
};

export const getUbiquityGovernanceContract = (address: string, provider: ethers.providers.Provider) => {
  return getContract(UbiquityGovernance.abi, address, provider);
};
