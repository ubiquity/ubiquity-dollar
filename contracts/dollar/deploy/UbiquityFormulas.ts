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

  const uAD = await deployments.deploy("UbiquityFormulas", opts);
  deployments.log("UbiquityFormulas deployed at:", uAD.address);
};
export default func;
func.tags = ["UbiquityFormulas"];
