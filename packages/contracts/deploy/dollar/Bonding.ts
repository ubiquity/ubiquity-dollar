import { DeployFuncParam } from "../utils";
import { create } from "../create"
import { constants } from "ethers"

export const optionDefinitions = [
    { name: 'task', defaultOption: true },
    { name: 'manager', alias: 'm', type: String }
]

const func = async (params: DeployFuncParam) => {
    const contractInstance = "src/dollar/Bonding.sol:Bonding";
    const { env, args } = params;
    const manager = args.manager;

    // TODO: Need to compare bytecode with previous deployedBytecode and deploy if there's a change.
    // If there's no change, we need to check `--force` flag
    const { stdout, stderr } = await create({ ...env, name: args.task, contractInstance, constructorArguments: [manager, constants.AddressZero] });
    return !stderr ? "succeeded" : "failed"
}
export default func;