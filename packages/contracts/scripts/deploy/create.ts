import fs from "fs";
import path from "path";
import { exportDeployment } from "./export";
import { Networks } from "../shared/constants/networks";
import { InputParams, ForgeArguments, AbiType } from "../shared/types";
import { execute, DeploymentResult } from "../shared";
import { loadEnv } from "../shared";
import { ethers } from "ethers";

export const create = async (args: ForgeArguments): Promise<{ result: DeploymentResult | undefined; stderr: string }> => {
  let flattenConstructorArgs = ``;
  if (args.constructorArguments.length > 0) {
    args.constructorArguments.forEach((elem) => {
      const param = Array.isArray(elem) ? `[${elem}]` : elem;
      flattenConstructorArgs += `${param} `;
    });
    flattenConstructorArgs = `--constructor-args ${flattenConstructorArgs}`;
  }

  const chainId = Networks[args.network] ?? undefined;
  if (!chainId) {
    throw new Error(`Unsupported network: ${args.network} Please configure it out first`);
  }

  const prepareCmd = `forge create ${args.contractInstance} --json --rpc-url ${args.rpcUrl} ${flattenConstructorArgs} --private-key ${args.privateKey}`;
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

export const getSigner = async () => {
  const env = await getENV();
  const signer = await new ethers.Wallet(env.privateKey, new ethers.providers.JsonRpcProvider(env.rpcUrl));
  return signer;
};

export const getContract = async (address: string, abi: AbiType) => {
  const signer = await getSigner();
  const CI = new ethers.Contract(address, abi, signer);
  return CI;
};

export const createHandler = async (constructorParams: string[], args: InputParams, contractInstance: string) => {
  const env = await getENV();
  const { result, stderr } = await create({
    ...env,
    name: args.task,
    network: args.network,
    contractInstance,
    constructorArguments: [...constructorParams],
  });

  console.log(!stderr ? `Deployed contract successfully. res: ${result}` : stderr);
  return { result, stderr };
};
