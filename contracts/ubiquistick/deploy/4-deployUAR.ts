import type { DeployFunction } from "hardhat-deploy/types";

import { HardhatRuntimeEnvironment } from "hardhat/types";

const deployUAR: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { ethers, deployments, getNamedAccounts } = hre;

  const { deploy } = deployments;
  const { deployer, treasury } = await getNamedAccounts();

  const deployResult = await deploy("UAR", {
    from: deployer,
    args: ["Ubiquity Auto Redeem", "uAR", treasury],
    log: true
  });
  // if (deployResult.newlyDeployed) {
  //   console.log("New UAR deployment");
  // }
};
deployUAR.tags = ["Tokens", "UAR"];
deployUAR.skip = async ({ network }) => network.name === "mainnet";

export default deployUAR;
