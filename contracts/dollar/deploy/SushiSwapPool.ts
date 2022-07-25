import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, ethers } = hre;
  const [admin] = await ethers.getSigners();
  deployments.log("admin address :", admin.address);

  const opts = {
    from: admin.address,
    log: true,
  };
  const mgr = await deployments.deploy("UbiquityAlgorithmicDollarManager", {
    args: [admin.address],
    ...opts,
  });
  const mgrFactory = await ethers.getContractFactory("UbiquityAlgorithmicDollarManager");

  const manager: UbiquityAlgorithmicDollarManager = mgrFactory.attach(mgr.address) as UbiquityAlgorithmicDollarManager;

  const uAD = await deployments.deploy("UbiquityAlgorithmicDollar", {
    args: [manager.address],
    ...opts,
  });
  await manager.setDollarTokenAddress(uAD.address);
  // uGov
  const uGov = await deployments.deploy("UbiquityGovernance", {
    args: [manager.address],
    ...opts,
  });
  await manager.setGovernanceTokenAddress(uGov.address);
  const sushiPool = await deployments.deploy("SushiSwapPool", {
    args: [manager.address],
    ...opts,
  });
  deployments.log("SushiSwapPool deployed at:", sushiPool.address);
};
export default func;
func.tags = ["SushiSwapPool"];
