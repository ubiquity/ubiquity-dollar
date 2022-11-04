import { OptionDefinition } from "command-line-args";

import { DeployFuncParam } from "../../shared";
import { create } from "../create"

export const optionDefinitions: OptionDefinition[] = [
    { name: 'task', defaultOption: true },
    { name: 'manager', alias: 'm', type: String },
    { name: "diamondCutFacet", alias: 'c', type: String },
    { name: "network", alias: 'n', type: String },
]

const func = async (params: DeployFuncParam) => {
    const contractInstance = "src/diamond/Diamond.sol:Diamond";
    const { env, args } = params;
    const manager = args.manager;
    const diamondCutFacet = args.diamondCutFacet;

    const { stderr } = await create({ ...env, name: args.task, network: args.network, contractInstance, constructorArguments: [manager, diamondCutFacet] });
    return !stderr ? "succeeded" : "failed"
}
export default func;