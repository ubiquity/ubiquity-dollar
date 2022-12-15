import { OptionDefinition } from "command-line-args";

import { DeployFuncParam } from "../../shared";
import { create } from "../create";

export const optionDefinitions: OptionDefinition[] = [
    { name: "task", defaultOption: true },
    { name: "manager", alias: "m", type: String },
    { name: "network", alias: "n", type: String },
    { name: "tos", alias: "t", type: String },
    { name: "amounts", alias: "a", type: String },
    { name: "stakingShareIDs", alias: "s", type: String },
];
const func = async (params: DeployFuncParam) => {
    const contractInstance = "src/dollar/UbiquityChef.sol:UbiquityChef";
    const { env, args } = params;
    const { manager, tos, amounts, stakingShareIDs } = args;
    const { result, stderr } = await create({
        ...env,
        name: args.task,
        network: args.network,
        contractInstance,
        constructorArguments: [manager, tos, amounts, stakingShareIDs],
    });
    return !stderr ? "succeeded" : "failed";
};
export default func;
