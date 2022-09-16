import { DeployFuncParam } from "../utils";
import { create } from "../create"

export const optionDefinitions = [
    { name: 'task', defaultOption: true },
    { name: 'manager', alias: 'm', type: String },
    { name: 'couponLengthBlocks', alias: 'c', type: String }
]

const func = async (params: DeployFuncParam) => {
    const contractInstance = "src/dollar/DebtCouponManager.sol:DebtCouponManager";
    const { env, args } = params;
    const manager = args.manager;
    // hardcoded value needs be configured like in constants or somewhere
    const couponLengthBlocks = args.couponLengthBlocks ?? 1110857

    const { result, stderr } = await create({ ...env, name: args.task, contractInstance, constructorArguments: [manager, couponLengthBlocks] });
    return !stderr ? "succeeded" : "failed"
}
export default func;