import { DeployFuncCallback } from "./utils";
import bondingFunc, { optionDefinitions as bondingOptions } from "./dollar/Bonding"
import uAdManagerFunc, { optionDefinitions as uadManagerOptions } from "./dollar/UbiquityAlgorithmDollarManager"
import bondingShareFunc, { optionDefinitions as bondingShareOptions } from "./dollar/BondingShare"
import bondingShareV2Func, { optionDefinitions as bondingShareV2Options } from "./dollar/BondingShareV2"
import couponsForDollarsCalculatorFunc, { optionDefinitions as couponsForDollarsCalculatorOptions } from "./dollar/CouponsForDollarsCalculator"
import curveUADIncentiveFunc, { optionDefinitions as curveUADIncentiveOptions } from "./dollar/CurveUADIncentive"
import debtCouponFunc, { optionDefinitions as debtCouponOptions } from "./dollar/DebtCoupon"
import debtCouponManagerFunc, { optionDefinitions as debtCouponManagerOptions } from "./dollar/DebtCouponManager"
import dollarMintingCalculatorFunc, { optionDefinitions as dollarMintingCalculatorOptions } from "./dollar/DollarMintingCalculator"
import excessDollarsDistributorFunc, { optionDefinitions as excessDollarsDistributorOptions } from "./dollar/ExcessDollarDistributor"
import masterChefFunc, { optionDefinitions as masterChefOptions } from "./dollar/MasterChef"
import ubiquityGovernanceFunc, { optionDefinitions as ubiquityGovernanceOptions } from "./dollar/UbiquityGovernance"
import sushiSwapPoolFunc, { optionDefinitions as sushiSwapPoolOptions } from "./dollar/UbiquityGovernance"
import uARForDollarsCalculatorFunc, { optionDefinitions as uARForDollarsCalculatorOptions } from "./dollar/UARForDollarsCalculator"
import ubiquityAlgorithmDollarFunc, { optionDefinitions as ubiquityAlgorithmDollarOptions } from "./dollar/UbiquityAlgorithmDollar"
import ubiquityAutoRedeemFunc, { optionDefinitions as ubiquityAutoRedeemOptions } from "./dollar/UbiquityAutoRedeem"
import ubiquityFormulaFunc, { optionDefinitions as ubiquityFormulaOptions } from "./dollar/UbiquityFormulas"
import yieldProxyFunc, { optionDefinitions as yieldProxyOptions } from "./dollar/YieldProxy"
import theUbiquityStickFunc, { optionDefinitions as theUbiquityStickOptions } from "./ubiquistick/TheUbiquityStick"
import theUbiquityStickSaleFunc, { optionDefinitions as theUbiquityStickSaleOptions } from "./ubiquistick/TheUbiquityStickSale"

export const DEPLOY_FUNCS: Record<string, { handler: DeployFuncCallback, options: any }> = {
    "Bonding": {
        handler: bondingFunc,
        options: bondingOptions
    },
    "UbiquityAlgorithmicDollarManager": {
        handler: uAdManagerFunc, options: uadManagerOptions
    },
    "BondingShare": {
        handler: bondingShareFunc,
        options: bondingShareOptions
    },
    "BondingShareV2": {
        handler: bondingShareV2Func,
        options: bondingShareV2Options
    },
    "CouponsForDollarsCalculator": {
        handler: couponsForDollarsCalculatorFunc,
        options: couponsForDollarsCalculatorOptions
    },
    "CurveUADIncentive": {
        handler: curveUADIncentiveFunc,
        options: curveUADIncentiveOptions
    },
    "DebtCoupon": {
        handler: debtCouponFunc,
        options: debtCouponOptions
    },
    "DebtCouponManager": {
        handler: debtCouponManagerFunc,
        options: debtCouponManagerOptions
    },
    "DollarMintingCalculator": {
        handler: dollarMintingCalculatorFunc,
        options: dollarMintingCalculatorOptions
    },
    "ExcessDollarDistributor": {
        handler: excessDollarsDistributorFunc,
        options: excessDollarsDistributorOptions
    },
    "MasterChef": {
        handler: masterChefFunc,
        options: masterChefOptions
    },
    "UbiquityGovernance": {
        handler: ubiquityGovernanceFunc,
        options: ubiquityGovernanceOptions
    },
    "SushiSwapPool": {
        handler: sushiSwapPoolFunc,
        options: sushiSwapPoolOptions
    },
    "UARForDollarsCalculator": {
        handler: uARForDollarsCalculatorFunc,
        options: uARForDollarsCalculatorOptions
    },
    "UbiquityAlgorithmDollar": {
        handler: ubiquityAlgorithmDollarFunc,
        options: ubiquityAlgorithmDollarOptions
    },
    "UbiquityAutoRedeem": {
        handler: ubiquityAutoRedeemFunc,
        options: ubiquityAutoRedeemOptions
    },
    "UbiquityFormulas": {
        handler: ubiquityFormulaFunc,
        options: ubiquityFormulaOptions
    },
    "YielProxy": {
        handler: yieldProxyFunc,
        options: yieldProxyOptions
    },
    "TheUbiquityStick": {
        handler: theUbiquityStickFunc,
        options: theUbiquityStickOptions
    },
    "TheUbiquityStickSale": {
        handler: theUbiquityStickSaleFunc,
        options: theUbiquityStickSaleOptions
    }
}