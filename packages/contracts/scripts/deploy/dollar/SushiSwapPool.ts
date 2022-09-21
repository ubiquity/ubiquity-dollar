import { DeployFuncParam } from "../utils";
import { create } from "../create"

export const optionDefinitions = [
    { name: 'task', defaultOption: true },
    { name: 'manager', alias: 'm', type: String },
    { name: "network", alias: 'n', type: String },
]

const func = async (params: DeployFuncParam) => {
    const contractInstance = "src/dollar/SushiSwapPool.sol:SushiSwapPool";
    const { env, args } = params;
    const manager = args.manager;

    const { stderr } = await create({ ...env, name: args.task, network: args.network, contractInstance, constructorArguments: [manager] });
    return !stderr ? "succeeded" : "failed"
}
export default func;