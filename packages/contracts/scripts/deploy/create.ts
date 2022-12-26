import fs from "fs";
import path from "path";
import { exportDeployment } from "./export";
import { Networks } from "../shared/constants/networks";
import { ArgsType, ForgeArguments } from "../shared/types";
import { execute, DeploymentResult } from "../shared";
import { loadEnv } from "../shared";

export const create = async (args: ForgeArguments): Promise<{ result: DeploymentResult | undefined; stderr: string; }> => {
  let flattenConstructorArgs = ``;
  for (const param of args.constructorArguments) {
    flattenConstructorArgs += `${param} `;
  }
  const chainId = Networks[args.network] ?? undefined;
  if (!chainId) {
    throw new Error(`Unsupported network: ${args.network} Please configure it out first`);
  }

  const prepareCmd = `forge create --json --rpc-url ${args.rpcUrl} --constructor-args ${flattenConstructorArgs} --private-key ${args.privateKey} ${args.contractInstance}`;
  let executeCmd: string;
  if (args.etherscanApiKey) {
    executeCmd = `${prepareCmd} --etherscan-api-key ${args.etherscanApiKey} --verify`;
  } else {
    executeCmd = prepareCmd;
  }
  let stdout;
  let stderr: string;
  let result: DeploymentResult | undefined;

  try {
    const { stdout: _stdout, stderr: _stderr } = await execute(executeCmd);
    stdout = _stdout;
    stderr = _stderr;
  } catch (err: any) {
    console.log(err);
    stdout = err?.stdout;
    stderr = err?.stderr;
  }
  if (stdout) {
    const regex = /{(?:[^{}]*|(R))*}/g;
    const found = stdout.match(regex);
    if (found && JSON.parse(found[0])?.deployedTo) {
      const { abi } = await import(`../../out/${args.name}.sol/${args.name}.json`);
      const { deployedTo, deployer, transactionHash } = JSON.parse(found[0]);
      result = { deployedTo, deployer, transactionHash };
      await exportDeployment(args.name, chainId.toString(), args.network, abi, deployedTo, deployer, transactionHash);
    }
  }

  console.log("result: ", stdout);
  console.log("error: ", stderr);

  return { result, stderr };
};

export const getENV = () => {
  const envPath = path.join(__dirname, "../../.env");
  if (!fs.existsSync(envPath)) {
    throw new Error("Env file not found");
  }
  const env = loadEnv(envPath);
  return env;
};

export const createHandler = async (params: string[], args: ArgsType, contractInstance: string) => {
  const env = await getENV();
  const { result, stderr } = await create({
    ...env,
    name: args.task,
    network: args.network,
    contractInstance,
    constructorArguments: [...params],
  });

  return !stderr ? "succeeded" : "failed";
};
