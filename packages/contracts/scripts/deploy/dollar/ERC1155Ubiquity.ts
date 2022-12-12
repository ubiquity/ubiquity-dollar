import { OptionDefinition } from "command-line-args";

import { DeployFuncParam } from "../../shared";
import { create } from "../create";

export const optionDefinitions: OptionDefinition[] = [
    { name: "task", defaultOption: true },
    { name: "manager", alias: "m", type: String },
    { name: "network", alias: "n", type: String },
    { name: "uri", alias: "u", type: String },
];

const func = async (params: DeployFuncParam) => {
    const contractInstance = "src/dollar/ERC1155Ubiquity.sol:ERC1155Ubiquity";
    const { env, args } = params;
    const { manager, uri } = args;
    const { result, stderr } = await create({
        ...env,
        name: args.task,
        network: args.network,
        contractInstance,
        constructorArguments: [manager, uri],
    });
    return !stderr ? "succeeded" : "failed";
};
export default func;
