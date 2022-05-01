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
  const uAD = await deployments.deploy("UbiquityAlgorithmicDollar", {
    args: [manager.address],
    ...opts,
  });
  deployments.log("UbiquityAlgorithmicDollar deployed at:", uAD.address);
};
export default func;
func.tags = ["UbiquityAlgorithmicDollar"];
