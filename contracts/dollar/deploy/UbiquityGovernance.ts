import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, ethers } = hre;
  const [admin] = await ethers.getSigners();
  deployments.log("admin address :", admin.address);

  const opts = {
    from: admin.address,
    log: true,
  };
  const manager = await deployments.deploy("UbiquityAlgorithmicDollarManager", {
    args: [admin.address],
    ...opts,
  });
  const uGov = await deployments.deploy("UbiquityGovernance", {
    args: [manager.address],
    ...opts,
  });
  deployments.log("UbiquityGovernance deployed at:", uGov.address);
};
export default func;
func.tags = ["UbiquityGovernance"];
