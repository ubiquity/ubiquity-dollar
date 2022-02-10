import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, ethers } = hre;
  const [admin] = await ethers.getSigners();
  const couponLengthBlocks = 1110857;
  deployments.log("admin address :", admin.address);

  const opts = {
    from: admin.address,
    log: true,
  };
  const manager = await deployments.deploy("UbiquityAlgorithmicDollarManager", {
    args: [admin.address],
    ...opts,
  });
  const uAD = await deployments.deploy("DebtCouponManager", {
    args: [manager.address, couponLengthBlocks],
    ...opts,
  });
  deployments.log("DebtCouponManager deployed at:", uAD.address);
};
export default func;
func.tags = ["DebtCouponManager"];
