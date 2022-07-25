import type { DeployFunction } from "hardhat-deploy/types";

import { HardhatRuntimeEnvironment } from "hardhat/types";

const deployLP: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;

  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  const deployResult = await deploy("LP", {
    from: deployer,
    args: ["LP token", "LP"],
    log: true,
  });
  if (deployResult.newlyDeployed) {
    console.log("New LP deployment");
  }
};
deployLP.tags = ["Tokens", "LP"];
deployLP.skip = async ({ network }) => network.name === "mainnet";

export default deployLP;
