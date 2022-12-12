import { OptionDefinition } from "command-line-args";

import { DeployFuncParam } from "../../shared";
import { create } from "../create";

export const optionDefinitions: OptionDefinition[] = [
    { name: "task", defaultOption: true },
    { name: "admin", alias: "a", type: String },
    { name: "network", alias: "n", type: String },
];

const func = async (params: DeployFuncParam) => {
    const contractInstance = "src/dollar/core/UbiquityDollarManager.sol:UbiquityDollarManager";
    const { env, args } = params;
    const admin = args.admin;
    const { result, stderr } = await create({
        ...env,
        name: args.task,
        network: args.network,
        contractInstance,
        constructorArguments: [admin],
    });
    return !stderr ? "succeeded" : "failed";
};
export default func;
