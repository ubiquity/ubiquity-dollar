import fs from "fs";
import path from "path";

export const deployments = async (chainId: string, name: string): Promise<{ address: string; deployer: string; transactionHash: string; abi: any }> => {
  const _path = path.join(__dirname, "../../../deployments.json");
  if (!fs.existsSync(_path)) {
    throw new Error("deployment file doesn't exist");
  }
  const _deployments = await import(_path);
  if (!_deployments[chainId]["contracts"][name]) {
    throw new Error(`Couldn't find deployment information for ${name}`);
  }

  return _deployments[chainId]["contracts"][name];
};
