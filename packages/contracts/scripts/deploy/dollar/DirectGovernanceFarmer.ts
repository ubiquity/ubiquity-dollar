import { OptionDefinition } from "command-line-args";

import { DeployFuncParam } from "../../shared";
import { create } from "../create";

export const optionDefinitions: OptionDefinition[] = [
  { name: "task", defaultOption: true },
  { name: "manager", alias: "m", type: String },
  { name: "network", alias: "n", type: String },
  { name: "base3Pool", alias: "b", type: String },
  { name: "depositZap", alias: "d", type: String },
];

const func = async (params: DeployFuncParam) => {
  const contractInstance = "src/dollar/DirectGovernanceFarmer.sol:DirectGovernanceFarmer";
  const { env, args } = params;
  const { manager, base3Pool, depositZap } = args;
  const { result, stderr } = await create({
    ...env,
    name: args.task,
    network: args.network,
    contractInstance,
    constructorArguments: [manager, base3Pool, depositZap],
  });
  return !stderr ? "succeeded" : "failed";
};
export default func;
