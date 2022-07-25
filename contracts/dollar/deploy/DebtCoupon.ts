import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";
import pressAnyKey from "../utils/flow";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, ethers } = hre;
  const [admin] = await ethers.getSigners();
  deployments.log("admin address :", admin.address);

  const opts = {
    from: admin.address,
    log: true,
  };
  let mgrAdr = "";
  if (mgrAdr.length === 0) {
    const manager = await deployments.deploy("UbiquityAlgorithmicDollarManager", {
      args: [admin.address],
      ...opts,
    });
    mgrAdr = manager.address;
  }

  const mgrFactory = await ethers.getContractFactory("UbiquityAlgorithmicDollarManager");

  const manager = mgrFactory.attach(
    mgrAdr // mgr.address
  ) as UbiquityAlgorithmicDollarManager;

  const debtCoupon = await deployments.deploy("DebtCoupon", {
    args: [mgrAdr],
    ...opts,
  });

  deployments.log("DebtCoupon deployed at:", debtCoupon.address);
  const debtCouponMgrBefore = await manager.debtCouponAddress();

  deployments.log("Manager DebtCoupon address at:", debtCoupon.address);
  if (debtCouponMgrBefore.toLowerCase() !== debtCoupon.address.toLowerCase()) {
    deployments.log("Will update manager DebtCoupon address from:", debtCouponMgrBefore, " to:", debtCoupon.address);
    await pressAnyKey();
    await (await manager.setDebtCouponAddress(debtCoupon.address)).wait(1);
    const debtCouponMgrAfter = await manager.debtCouponAddress();
    deployments.log("Manager DebtCoupon address at:", debtCouponMgrAfter);
  }
};
export default func;
func.tags = ["DebtCoupon"];
