import { OptionDefinition } from "command-line-args";

import { DeployFuncParam } from "../../../shared";
import { create } from "../../create";

export const optionDefinitions: OptionDefinition[] = [
    { name: "task", defaultOption: true },
    { name: "manager", alias: "m", type: String },
    { name: "network", alias: "n", type: String },
    { name: "creditNFTLengthBlocks", alias: "c", type: Number },
];

const func = async (params: DeployFuncParam) => {
    const contractInstance = "src/dollar/core/CreditNFTManager.sol:CreditNFTManager";
    const { env, args } = params;
    const manager = args.manager;
    const creditNFTLengthBlocks = args.creditNFTLengthBlocks;
    const { result, stderr } = await create({
        ...env,
        name: args.task,
        network: args.network,
        contractInstance,
        constructorArguments: [manager, creditNFTLengthBlocks],
    });
    return !stderr ? "succeeded" : "failed";
};
export default func;
