import { OptionDefinition } from "command-line-args";

import { DeployFuncParam } from "../../shared";
import { create } from "../create";

export const optionDefinitions: OptionDefinition[] = [
  { name: "task", defaultOption: true },
  { name: "treasury", alias: "t", type: String },
];

const func = async (params: DeployFuncParam) => {
  const contractInstance = "src/ubiquistick/UAR.sol:UAR";
  const { env, args } = params;
  const treasury = args.treasury;

  const { result, stderr } = await create({
    ...env,
    name: args.task,
    network: args.network,
    contractInstance,
    constructorArguments: ["Ubiquity Auto Redeem", "uAR", treasury],
  });
  return !stderr ? "succeeded" : "failed";
};
export default func;
