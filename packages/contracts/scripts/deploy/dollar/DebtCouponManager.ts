import { OptionDefinition } from "command-line-args";

import { DeployFuncParam } from "../../shared";
import { create } from "../create"

export const optionDefinitions: OptionDefinition[] = [
    { name: 'task', defaultOption: true },
    { name: 'manager', alias: 'm', type: String },
    { name: 'couponLengthBlocks', alias: 'c', type: String },
    { name: "network", alias: 'n', type: String },
]

const func = async (params: DeployFuncParam) => {
    const contractInstance = "src/dollar/DebtCouponManager.sol:DebtCouponManager";
    const { env, args } = params;
    const manager = args.manager;
    // hardcoded value needs be configured like in constants or somewhere
    const couponLengthBlocks = args.couponLengthBlocks ?? 1110857

    const { result, stderr } = await create({ ...env, name: args.task, contractInstance, network: args.network, constructorArguments: [manager, couponLengthBlocks] });
    return !stderr ? "succeeded" : "failed"
}
export default func;