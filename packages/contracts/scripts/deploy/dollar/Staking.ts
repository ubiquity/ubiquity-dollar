import { OptionDefinition } from "command-line-args";

import { DeployFuncParam } from "../../shared";
import { create } from "../create";

export const optionDefinitions: OptionDefinition[] = [
    { name: "task", defaultOption: true },
    { name: "manager", alias: "m", type: String },
    { name: "network", alias: "n", type: String },
    { name: "stakingFormulasAddress", alias: "s", type: String },
    { name: "originals", alias: "o", type: String },
    { name: "lpBalances", alias: "l", type: String },
    { name: "weeks", alias: "w", type: String },
];
const func = async (params: DeployFuncParam) => {
    const contractInstance = "src/dollar/Staking.sol:Staking";
    const { env, args } = params;
    const { manager, stakingFormulasAddress, originals, lpBalances, weeks } = args;
    const { result, stderr } = await create({
        ...env,
        name: args.task,
        network: args.network,
        contractInstance,
        constructorArguments: [manager, stakingFormulasAddress, originals, lpBalances, weeks],
    });
    return !stderr ? "succeeded" : "failed";
};
export default func;
