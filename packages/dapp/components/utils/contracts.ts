import { ethers } from "ethers";

import {
  ChainlinkPriceFeed__factory,
  CreditNFTManager__factory,
  CreditNFT__factory,
  DAIToken__factory,
  DollarMintCalculator__factory,
  ERC1155Ubiquity__factory,
  ERC20__factory,
  ICreditNFTRedemptionCalculator__factory,
  ICreditRedemptionCalculator__factory,
  ICurveFactory__factory,
  IJar__factory,
  IMetaPool__factory,
  SimpleBond__factory,
  StakingShare__factory,
  Staking__factory,
  SushiSwapPool__factory,
  TWAPOracleDollar3pool__factory,
  UbiquiStickSale__factory,
  UbiquiStick__factory,
  UbiquityChef__factory,
  UbiquityCreditToken__factory,
  UbiquityDollarManager__factory,
  UbiquityDollarToken__factory,
  UbiquityFormulas__factory,
  UbiquityGovernanceToken__factory,
  UniswapV2Pair__factory,
  UniswapV3Pool__factory,
  UniswapV3Router__factory,
  USDCToken__factory,
  USDTToken__factory,
  YieldProxy__factory,
} from "@/types/contracts";

export const getUniswapV2FactoryContract = (address: string, provider: ethers.providers.Provider) => {
  return UniswapV2Pair__factory.connect(address, provider);
};

export const getUniswapV3PoolContract = (address: string, provider: ethers.providers.Provider) => {
  return UniswapV3Pool__factory.connect(address, provider);
};

export const getUniswapV3RouterContract = (address: string, provider: ethers.providers.Provider) => {
  return UniswapV3Router__factory.connect(address, provider);
};

export const getChainlinkPriceFeedContract = (address: string, provider: ethers.providers.Provider) => {
  return ChainlinkPriceFeed__factory.connect(address, provider);
};

export const getERC20Contract = (address: string, provider: ethers.providers.Provider) => {
  return ERC20__factory.connect(address, provider);
};

export const getERC1155UbiquityContract = (address: string, provider: ethers.providers.Provider) => {
  return ERC1155Ubiquity__factory.connect(address, provider);
};

export const getSimpleBondContract = (address: string, provider: ethers.providers.Provider) => {
  return SimpleBond__factory.connect(address, provider);
};

export const getUbiquiStickContract = (address: string, provider: ethers.providers.Provider) => {
  return UbiquiStick__factory.connect(address, provider);
};

export const getUbiquiStickSaleContract = (address: string, provider: ethers.providers.Provider) => {
  return UbiquiStickSale__factory.connect(address, provider);
};

export const getIJarContract = (address: string, provider: ethers.providers.Provider) => {
  return IJar__factory.connect(address, provider);
};

export const getDebtCouponManagerContract = (address: string, provider: ethers.providers.Provider) => {
  return CreditNFTManager__factory.connect(address, provider);
};

export const getCurveFactoryContract = (address: string, provider: ethers.providers.Provider) => {
  return ICurveFactory__factory.connect(address, provider);
};

export const getYieldProxyContract = (address: string, provider: ethers.providers.Provider) => {
  return YieldProxy__factory.connect(address, provider);
};

export const getBondingShareV2Contract = (address: string, provider: ethers.providers.Provider) => {
  return StakingShare__factory.connect(address, provider);
};

export const getBondingV2Contract = (address: string, provider: ethers.providers.Provider) => {
  return Staking__factory.connect(address, provider);
};

export const getDebtCouponContract = (address: string, provider: ethers.providers.Provider) => {
  return CreditNFT__factory.connect(address, provider);
};

export const getTWAPOracleContract = (address: string, provider: ethers.providers.Provider) => {
  return TWAPOracleDollar3pool__factory.connect(address, provider);
};

export const getDollarMintingCalculatorContract = (address: string, provider: ethers.providers.Provider) => {
  return DollarMintCalculator__factory.connect(address, provider);
};

export const getICouponsForDollarsCalculatorContract = (address: string, provider: ethers.providers.Provider) => {
  return ICreditNFTRedemptionCalculator__factory.connect(address, provider);
};

export const getIUARForDollarsCalculatorContract = (address: string, provider: ethers.providers.Provider) => {
  return ICreditRedemptionCalculator__factory.connect(address, provider);
};

export const getIMetaPoolContract = (address: string, provider: ethers.providers.Provider) => {
  return IMetaPool__factory.connect(address, provider);
};

export const getMasterChefV2Contract = (address: string, provider: ethers.providers.Provider) => {
  return UbiquityChef__factory.connect(address, provider);
};

export const getSushiSwapPoolContract = (address: string, provider: ethers.providers.Provider) => {
  return SushiSwapPool__factory.connect(address, provider);
};

export const getUbiquityDollarManagerContract = (address: string, provider: ethers.providers.Provider) => {
  return UbiquityDollarManager__factory.connect(address, provider);
};

export const getUbiquityDollarContract = (address: string, provider: ethers.providers.Provider) => {
  return UbiquityDollarToken__factory.connect(address, provider);
};

export const getUbiquityCreditContract = (address: string, provider: ethers.providers.Provider) => {
  return UbiquityCreditToken__factory.connect(address, provider);
};

export const getUbiquityFormulasContract = (address: string, provider: ethers.providers.Provider) => {
  return UbiquityFormulas__factory.connect(address, provider);
};

export const getUbqContract = (address: string, provider: ethers.providers.Provider) => {
  return UbiquityGovernanceToken__factory.connect(address, provider);
};

export const getUSDCTokenContract = (address: string, provider: ethers.providers.Provider) => {
  return USDCToken__factory.connect(address, provider);
};

export const getDAITokenContract = (address: string, provider: ethers.providers.Provider) => {
  return DAIToken__factory.connect(address, provider);
};

export const getUSDTTokenContract = (address: string, provider: ethers.providers.Provider) => {
  return USDTToken__factory.connect(address, provider);
};
