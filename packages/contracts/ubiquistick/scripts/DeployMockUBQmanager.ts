import { DeployFunction } from "hardhat-deploy/types";

const deployMockUBQmanager: DeployFunction = async function ({ deployments, getNamedAccounts }) {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  await deploy("MockUBQmanager", {
    from: deployer,
    args: [],
    log: true,
  });
};
deployMockUBQmanager.skip = async ({ getChainId }) => {
  return Number(await getChainId()) === 1;
};
deployMockUBQmanager.tags = ["MockUBQmanager"];

export default deployMockUBQmanager;
