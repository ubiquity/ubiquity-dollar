import { DeployFuncParam } from "../utils";
import { create } from "../create"
import { constants } from "ethers"

export const optionDefinitions = [
    { name: 'task', defaultOption: true },
    { name: 'manager', alias: 'm', type: String }
]

const func = async (params: DeployFuncParam) => {
    const contractInstance = "src/dollar/BondingShare.sol:BondingShare";
    const { env, args } = params;
    const manager = args.manager;

    const { stdout, stderr } = await create({ ...env, name: args.task, contractInstance, constructorArguments: [manager] });
    return !stderr ? "succeeded" : "failed"
}
export default func;