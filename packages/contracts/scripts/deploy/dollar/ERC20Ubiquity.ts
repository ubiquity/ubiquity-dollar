import { OptionDefinition } from "command-line-args";

import { DeployFuncParam } from "../../shared";
import { create } from "../create";

export const optionDefinitions: OptionDefinition[] = [
    { name: "task", defaultOption: true },
    { name: "manager", alias: "m", type: String },
    { name: "network", alias: "n", type: String },
    { name: "name", alias: "n", type: String },
    { name: "symbol", alias: "s", type: String },
];

const func = async (params: DeployFuncParam) => {
    const contractInstance = "src/dollar/ERC20Ubiquity.sol:ERC20Ubiquity";
    const { env, args } = params;
    const { manager, name, symbol } = args;
    const { result, stderr } = await create({
        ...env,
        name: args.task,
        network: args.network,
        contractInstance,
        constructorArguments: [manager, name, symbol],
    });
    return !stderr ? "succeeded" : "failed";
};
export default func;
