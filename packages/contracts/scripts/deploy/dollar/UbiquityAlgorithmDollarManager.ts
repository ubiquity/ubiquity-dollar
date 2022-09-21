import { create } from "../create"
import { DeployFuncParam } from "../../shared";

export const optionDefinitions = [
    { name: 'task', defaultOption: true },
    { name: 'admin', alias: 'a', type: String },
    { name: "network", alias: 'n', type: String },
]

const func = async (params: DeployFuncParam) => {
    const contractInstance = "src/dollar/UbiquityAlgorithmicDollarManager.sol:UbiquityAlgorithmicDollarManager";
    const { env, args } = params;
    const admin_addr = args.admin;

    // TODO: Need to compare bytecode with previous deployedBytecode and deploy if there's a change.
    // If there's no change, we need to check `--force` flag
    const { stderr } = await create({ ...env, name: args.task, network: args.network, contractInstance, constructorArguments: [admin_addr] });
    return !stderr ? "succeeded" : "failed"
}
export default func;
