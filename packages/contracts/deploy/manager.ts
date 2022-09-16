import { DeployFuncCallback } from "./utils";
import bondingFunc, { optionDefinitions as bondingOptions } from "./dollar/Bonding"
import uAdManagerFunc, { optionDefinitions as uadManagerOptions } from "./dollar/UbiquityAlgorithmDollarManager"
import bondingShareFunc, { optionDefinitions as bondingShareOptions } from "./dollar/BondingShare"
import bondingShareV2Func, { optionDefinitions as bondingShareV2Options } from "./dollar/BondingShareV2"
import couponsForDollarsCalculatorFunc, { optionDefinitions as couponsForDollarsCalculatorOptions } from "./dollar/CouponsForDollarsCalculator"
import curveUADIncentiveFunc, { optionDefinitions as curveUADIncentiveOptions } from "./dollar/CurveUADIncentive"
import debtCouponFunc, { optionDefinitions as debtCouponOptions } from "./dollar/DebtCoupon"
import debtCouponManagerFunc, { optionDefinitions as debtCouponManagerOptions } from "./dollar/DebtCouponManager"
import dollarMintingCalculatorFunc, { optionDefinitions as dollarMintingCalculatorOptions } from "./dollar/DebtCouponManager"

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
    }
}