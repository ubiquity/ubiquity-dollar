import { ethers } from "ethers";
import UniswapV2PairABI from "../config/abis/UniswapV2Pair.json"
import UniswapV3PoolABI from "../config/abis/UniswapV3Pool.json"
import ChainlinkPriceFeedABI from "../config/abis/ChainlinkPriceFeed.json"
import ERC20ABI from "../config/abis/ERC20.json"

import { abi as SimpleBondABI } from "@ubiquity/ubiquistick/artifacts/contracts/SimpleBond.sol/SimpleBond.json"
import { abi as UbiquityStickABI } from "@ubiquity/ubiquistick/artifacts/contracts/TheUbiquityStick.sol/TheUbiquityStick.json"
import { abi as UbiquityStickSaleABI } from "@ubiquity/ubiquistick/artifacts/contracts/TheUbiquityStickSale.sol/TheUbiquityStickSale.json"
import { abi as ERC1155UbiquityABI } from "@ubiquity/dollar/artifacts/contracts/ERC1155Ubiquity.sol/ERC1155Ubiquity.json"
import { abi as IJarABI } from "@ubiquity/dollar/artifacts/contracts/interfaces/IJar.sol/IJar.json"
import { abi as DebtCouponManagerABI } from "@ubiquity/dollar/artifacts/contracts/DebtCouponManager.sol/DebtCouponManager.json"
import { abi as ICurveFactoryABI } from "@ubiquity/dollar/artifacts/contracts/interfaces/ICurveFactory.sol/ICurveFactory.json"
import { abi as YieldProxyABI } from "@ubiquity/dollar/artifacts/contracts/YieldProxy.sol/YieldProxy.json"
import { abi as BondingShareV2ABI } from "@ubiquity/dollar/artifacts/contracts/BondingShareV2.sol/BondingShareV2.json"
import { abi as BondingV2ABI } from "@ubiquity/dollar/artifacts/contracts/BondingV2.sol/BondingV2.json"
import { abi as DebtCouponABI } from "@ubiquity/dollar/artifacts/contracts/DebtCoupon.sol/DebtCoupon.json"
import { abi as DollarMintingCalculatorABI } from "@ubiquity/dollar/artifacts/contracts/DollarMintingCalculator.sol/DollarMintingCalculator.json"
import { abi as ICouponsForDollarsCalculatorABI } from "@ubiquity/dollar/artifacts/contracts/interfaces/ICouponsForDollarsCalculator.sol/ICouponsForDollarsCalculator.json"
import { abi as IMetaPoolABI } from "@ubiquity/dollar/artifacts/contracts/interfaces/IMetaPool.sol/IMetaPool.json"
import { abi as IUARForDollarsCalculatorABI } from "@ubiquity/dollar/artifacts/contracts/interfaces/IUARForDollarsCalculator.sol/IUARForDollarsCalculator.json"
import { abi as MasterChefv2ABI } from "@ubiquity/dollar/artifacts/contracts/MasterChefV2.sol/MasterChefV2.json"
import { abi as SushiSwapPoolABI } from "@ubiquity/dollar/artifacts/contracts/SushiSwapPool.sol/SushiSwapPool.json"
import { abi as TWAPOracleABI } from "@ubiquity/dollar/artifacts/contracts/TWAPOracle.sol/TWAPOracle.json"
import { abi as UbiquityAlgorithmicDollarManagerABI } from "@ubiquity/dollar/artifacts/contracts/UbiquityAlgorithmicDollarManager.sol/UbiquityAlgorithmicDollarManager.json"
import { abi as UbiquityAlgorithmicDollarABI } from "@ubiquity/dollar/artifacts/contracts/UbiquityAlgorithmicDollar.sol/UbiquityAlgorithmicDollar.json"
import { abi as UbiquityAutoRedeemABI } from "@ubiquity/dollar/artifacts/contracts/UbiquityAutoRedeem.sol/UbiquityAutoRedeem.json"
import { abi as UbiquityFormulasABI } from "@ubiquity/dollar/artifacts/contracts/UbiquityFormulas.sol/UbiquityFormulas.json"
import { abi as UbiquityGovernanceABI } from "@ubiquity/dollar/artifacts/contracts/UbiquityGovernance.sol/UbiquityGovernance.json"

const getContract = (
    abi: any,
    address: string,
    provider: ethers.providers.Provider
) => {
    return new ethers.Contract(address, abi, provider);
};

export const getUniswapV2FactoryContract = (address: string, provider: ethers.providers.Provider) => {
    return getContract(UniswapV2PairABI, address, provider);
}

export const getUniswapV3PoolContract = (address: string, provider: ethers.providers.Provider) => {
    return getContract(UniswapV3PoolABI, address, provider);
}

export const getChainlinkPriceFeedContract = (address: string, provider: ethers.providers.Provider): ethers.Contract => {
    return getContract(ChainlinkPriceFeedABI, address, provider);
}

export const getERC20Contract = (
    address: string,
    provider: ethers.providers.Provider
) => {
    return getContract(ERC20ABI, address, provider);
};

export const getERC1155UbiquityContract = (address: string, provider: ethers.providers.Provider) => {
    return getContract(ERC1155UbiquityABI, address, provider);
}

export const getSimpleBondContract = (address: string, provider: ethers.providers.Provider) => {
    return getContract(SimpleBondABI, address, provider);
}

export const getUbiquitystickContract = (address: string, provider: ethers.providers.Provider) => {
    return getContract(UbiquityStickABI, address, provider);
}

export const getUbiquityStickSaleContract = (address: string, provider: ethers.providers.Provider) => {
    return getContract(UbiquityStickSaleABI, address, provider);
}

export const getIJarContract = (address: string, provider: ethers.providers.Provider) => {
    return getContract(IJarABI, address, provider);
}

export const getDebtCouponManagerContract = (address: string, provider: ethers.providers.Provider) => {
    return getContract(DebtCouponManagerABI, address, provider);
}

export const getCurveFactoryContract = (address: string, provider: ethers.providers.Provider) => {
    return getContract(ICurveFactoryABI, address, provider);
}

export const getYieldProxyContract = (address: string, provider: ethers.providers.Provider) => {
    return getContract(YieldProxyABI, address, provider);
}

export const getBondingShareV2Contract = (address: string, provider: ethers.providers.Provider) => {
    return getContract(BondingShareV2ABI, address, provider);
}

export const getBondingV2Contract = (address: string, provider: ethers.providers.Provider) => {
    return getContract(BondingV2ABI, address, provider);
}

export const getDebtCouponContract = (address: string, provider: ethers.providers.Provider) => {
    return getContract(DebtCouponABI, address, provider);
}

export const getTWAPOracleContract = (address: string, provider: ethers.providers.Provider) => {
    return getContract(TWAPOracleABI, address, provider);
}

export const getDollarMintingCalculatorContract = (address: string, provider: ethers.providers.Provider) => {
    return getContract(DollarMintingCalculatorABI, address, provider);
}

export const getICouponsForDollarsCalculatorContract = (address: string, provider: ethers.providers.Provider) => {
    return getContract(ICouponsForDollarsCalculatorABI, address, provider);
}

export const getIUARForDollarsCalculatorContract = (address: string, provider: ethers.providers.Provider) => {
    return getContract(IUARForDollarsCalculatorABI, address, provider);
}

export const getIMetaPoolContract = (address: string, provider: ethers.providers.Provider) => {
    return getContract(IMetaPoolABI, address, provider);
}

export const getMasterChefv2Contract = (address: string, provider: ethers.providers.Provider) => {
    return getContract(MasterChefv2ABI, address, provider);
}

export const getSushiSwapPoolContract = (address: string, provider: ethers.providers.Provider) => {
    return getContract(SushiSwapPoolABI, address, provider);
}

export const getUbiquityAlgorithmicDollarManagerContract = (address: string, provider: ethers.providers.Provider) => {
    return getContract(UbiquityAlgorithmicDollarManagerABI, address, provider);
}

export const getUbiquityAlgorithmicDollarContract = (address: string, provider: ethers.providers.Provider) => {
    return getContract(UbiquityAlgorithmicDollarABI, address, provider);
}

export const getUbiquityAutoRedeemContract = (address: string, provider: ethers.providers.Provider) => {
    return getContract(UbiquityAutoRedeemABI, address, provider);
}

export const getUbiquityFormulasContract = (address: string, provider: ethers.providers.Provider) => {
    return getContract(UbiquityFormulasABI, address, provider);
}

export const getUbiquityGovernanceContract = (address: string, provider: ethers.providers.Provider) => {
    return getContract(UbiquityGovernanceABI, address, provider);
}

