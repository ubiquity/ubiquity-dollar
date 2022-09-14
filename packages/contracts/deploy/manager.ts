import { DeployFuncCallback } from "./utils";
import bondingFunc from "./dollar/Bonding"
import uAdManagerFunc from "./dollar/UbiquityAlgorithmDollarManater"

export const DEPLOY_FUNCS: Record<string, DeployFuncCallback> = {
    "bonding": bondingFunc,
    "uad-manager": uAdManagerFunc
}