import { DeployFuncCallback } from "./utils";
import bondingFunc, { optionDefinitions as bondingOptions } from "./dollar/Bonding"
import uAdManagerFunc, { optionDefinitions as uadManagerOptions } from "./dollar/UbiquityAlgorithmDollarManager"
import bondingShareFunc, { optionDefinitions as bondingShareOptions } from "./dollar/BondingShare"

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
    }
}