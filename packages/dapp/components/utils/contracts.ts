/* eslint-disable no-unused-vars */
import { Provider } from "@ethersproject/providers";
import { ContractInterface, ethers } from "ethers";

// ARTIFACTS
import _DebtCoupon from "@ubiquity/contracts/out/CreditNft.sol/CreditNft.json";
import _DebtCouponManager from "@ubiquity/contracts/out/CreditNftManagerFacet.sol/CreditNftManagerFacet.json";
import _DollarMintCalculator from "@ubiquity/contracts/out/DollarMintCalculatorFacet.sol/DollarMintCalculatorFacet.json";
import _ERC1155Ubiquity from "@ubiquity/contracts/out/ERC1155Ubiquity.sol/ERC1155Ubiquity.json";
import _ICouponsForDollarsCalculator from "@ubiquity/contracts/out/ICreditNftRedemptionCalculator.sol/ICreditNftRedemptionCalculator.json";
import _IUARForDollarsCalculator from "@ubiquity/contracts/out/ICreditRedemptionCalculator.sol/ICreditRedemptionCalculator.json";
import _ICurveFactory from "@ubiquity/contracts/out/ICurveFactory.sol/ICurveFactory.json";
import _IJar from "@ubiquity/contracts/out/IJar.sol/IJar.json";
import _IMetaPool from "@ubiquity/contracts/out/IMetaPool.sol/IMetaPool.json";
import _SimpleBond from "@ubiquity/contracts/out/SimpleBond.sol/SimpleBond.json";
import _Staking from "@ubiquity/contracts/out/StakingFacet.sol/StakingFacet.json";
import _StakingToken from "@ubiquity/contracts/out/StakingShare.sol/StakingShare.json";
import _SushiSwapPool from "@ubiquity/contracts/out/SushiSwapPool.sol/SushiSwapPool.json";
import _TWAPOracle from "@ubiquity/contracts/out/TWAPOracleDollar3poolFacet.sol/TWAPOracleDollar3poolFacet.json";
import _UbiquiStick from "@ubiquity/contracts/out/UbiquiStick.sol/UbiquiStick.json";
import _UbiquiStickSale from "@ubiquity/contracts/out/UbiquiStickSale.sol/UbiquiStickSale.json";
import _MasterChefV2 from "@ubiquity/contracts/out/ChefFacet.sol/ChefFacet.json";
import _Credit from "@ubiquity/contracts/out/UbiquityCreditToken.sol/UbiquityCreditToken.json";
import _UbiquityManager from "@ubiquity/contracts/out/ManagerFacet.sol/ManagerFacet.json";
import _Dollar from "@ubiquity/contracts/out/UbiquityDollarToken.sol/UbiquityDollarToken.json";
import _UbiquityFormulas from "@ubiquity/contracts/out/StakingFormulasFacet.sol/StakingFormulasFacet.json";
import _Governance from "@ubiquity/contracts/out/UbiquityGovernanceToken.sol/UbiquityGovernanceToken.json";

// ABIs
import ChainlinkPriceFeedABI from "../config/abis/ChainlinkPriceFeed.json";
import DAITokenABI from "../config/abis/DAIToken.json";
import ERC20ABI from "../config/abis/ERC20.json";
import UniswapV2PairABI from "../config/abis/UniswapV2Pair.json";
import UniswapV3PoolABI from "../config/abis/UniswapV3Pool.json";
import UniswapV3RouterABI from "../config/abis/UniswapV3Router.json";
import USDCTokenABI from "../config/abis/USDCToken.json";
import USDTTokenABI from "../config/abis/USDTToken.json";
import YieldProxyABI from "../config/abis/YieldProxy.json";

import {
  CreditNft,
  CreditNftManagerFacet,
  CreditNftRedemptionCalculatorFacet,
  CreditRedemptionCalculatorFacet,
  DollarMintCalculatorFacet,
  ERC1155Ubiquity,
  ERC20,
  ICurveFactory,
  IJar,
  IMetaPool,
  ITWAPOracleDollar3pool,
  IUniswapV2Pair,
  SimpleBond,
  StakingFacet,
  StakingShare,
  SushiSwapPool,
  UbiquiStick,
  UbiquiStickSale,
  ChefFacet,
  UbiquityCreditToken,
  ManagerFacet,
  UbiquityDollarToken,
  StakingFormulasFacet,
  UbiquityGovernanceToken,
} from "types";

const getContract = (abi: ContractInterface, address: string, provider: Provider) => {
  return new ethers.Contract(address, abi, provider);
};

export const getUniswapV2PairContract = (address: string, provider: Provider) => {
  return getContract(UniswapV2PairABI, address, provider) as IUniswapV2Pair;
};

export const getUniswapV3PoolContract = (address: string, provider: Provider) => {
  return getContract(UniswapV3PoolABI, address, provider); // as UniswapV3Pool;
};
export const getUniswapV3RouterContract = (address: string, provider: Provider) => {
  return getContract(UniswapV3RouterABI, address, provider); // as ISwapRouter;
};

export const getChainlinkPriceFeedContract = (address: string, provider: Provider): ethers.Contract => {
  return getContract(ChainlinkPriceFeedABI, address, provider); // as ChainlinkPriceFeed;
};

export const getERC20Contract = (address: string, provider: Provider) => {
  return getContract(ERC20ABI, address, provider) as ERC20;
};

export const getERC1155UbiquityContract = (address: string, provider: Provider) => {
  return getContract(_ERC1155Ubiquity.abi, address, provider) as ERC1155Ubiquity;
};

export const getSimpleBondContract = (address: string, provider: Provider) => {
  return getContract(_SimpleBond.abi, address, provider) as SimpleBond;
};

export const getUbiquiStickContract = (address: string, provider: Provider) => {
  return getContract(_UbiquiStick.abi, address, provider) as UbiquiStick;
};

export const getUbiquiStickSaleContract = (address: string, provider: Provider) => {
  return getContract(_UbiquiStickSale.abi, address, provider) as UbiquiStickSale;
};

export const getIJarContract = (address: string, provider: Provider) => {
  return getContract(_IJar.abi, address, provider) as IJar;
};

export const getDebtCouponManagerContract = (address: string, provider: Provider) => {
  return getContract(_DebtCouponManager.abi, address, provider) as CreditNftManagerFacet;
};

export const getCurveFactoryContract = (address: string, provider: Provider) => {
  return getContract(_ICurveFactory.abi, address, provider) as ICurveFactory;
};

export const getYieldProxyContract = (address: string, provider: Provider) => {
  return getContract(YieldProxyABI, address, provider); // as YieldProxy;
};

export const getStakingShareContract = (address: string, provider: Provider) => {
  return getContract(_StakingToken.abi, address, provider) as StakingShare;
};

export const getBondingV2Contract = (address: string, provider: Provider) => {
  return getContract(_Staking.abi, address, provider) as StakingFacet;
};

export const getDebtCouponContract = (address: string, provider: Provider) => {
  return getContract(_DebtCoupon.abi, address, provider) as CreditNft;
};

export const getTWAPOracleContract = (address: string, provider: Provider) => {
  return getContract(_TWAPOracle.abi, address, provider) as ITWAPOracleDollar3pool;
};

export const getDollarMintCalculatorContract = (address: string, provider: Provider) => {
  return getContract(_DollarMintCalculator.abi, address, provider) as DollarMintCalculatorFacet;
};

export const getICouponsForDollarsCalculatorContract = (address: string, provider: Provider) => {
  return getContract(_ICouponsForDollarsCalculator.abi, address, provider) as CreditNftRedemptionCalculatorFacet;
};

export const getIUARForDollarsCalculatorContract = (address: string, provider: Provider) => {
  return getContract(_IUARForDollarsCalculator.abi, address, provider) as CreditRedemptionCalculatorFacet;
};

export const getIMetaPoolContract = (address: string, provider: Provider) => {
  return getContract(_IMetaPool.abi, address, provider) as IMetaPool;
};

export const getMasterChefV2Contract = (address: string, provider: Provider) => {
  return getContract(_MasterChefV2.abi, address, provider) as ChefFacet;
};

export const getSushiSwapPoolContract = (address: string, provider: Provider) => {
  return getContract(_SushiSwapPool.abi, address, provider) as SushiSwapPool;
};

export const getUbiquityManagerContract = (address: string, provider: Provider) => {
  return getContract(_UbiquityManager.abi, address, provider) as ManagerFacet;
};

export const getDollarContract = (address: string, provider: Provider) => {
  return getContract(_Dollar.abi, address, provider) as UbiquityDollarToken;
};

export const getCreditContract = (address: string, provider: Provider) => {
  return getContract(_Credit.abi, address, provider) as UbiquityCreditToken;
};

export const getUbiquityFormulasContract = (address: string, provider: Provider) => {
  return getContract(_UbiquityFormulas.abi, address, provider) as StakingFormulasFacet;
};

export const getGovernanceContract = (address: string, provider: Provider) => {
  return getContract(_Governance.abi, address, provider) as UbiquityGovernanceToken;
};

export const getUSDCTokenContract = (address: string, provider: Provider) => {
  return getContract(USDCTokenABI, address, provider) as ERC20;
};

export const getDAITokenContract = (address: string, provider: Provider) => {
  return getContract(DAITokenABI, address, provider) as ERC20;
};

export const getUSDTTokenContract = (address: string, provider: Provider) => {
  return getContract(USDTTokenABI, address, provider) as ERC20;
};
