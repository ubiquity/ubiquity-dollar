import { OptionDefinition } from "command-line-args";

import { DeployFuncParam } from "../../shared";
import { create } from "../create";

export const optionDefinitions: OptionDefinition[] = [
    { name: "task", defaultOption: true },
    { name: "pool", alias: "p", type: String },
    { name: "dollarToken0", alias: "d", type: String },
    { name: "curve3CRVToken1", alias: "c", type: String },
];
const func = async (params: DeployFuncParam) => {
    const contractInstance = "src/dollar/core/TWAPOracleDollar3pool.sol:TWAPOracleDollar3pool";
    const { env, args } = params;
    const pool = args.pool;
    const dollarToken0 = args.dollarToken0;
    const curve3CRVToken1 = args.curve3CRVToken1;
    const { result, stderr } = await create({
        ...env,
        name: args.task,
        network: args.network,
        contractInstance,
        constructorArguments: [pool, dollarToken0, curve3CRVToken1],
    });
    return !stderr ? "succeeded" : "failed";
};
export default func;
