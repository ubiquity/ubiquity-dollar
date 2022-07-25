import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";
import { YieldProxy } from "../artifacts/types/YieldProxy";
import { IJar } from "../artifacts/types/IJar";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, ethers } = hre;
  // production 0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98
  let mgrAdr = "0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98";
  // pickle Jars https://github.com/pickle-finance/contracts#pickle-jars-pjars
  // pYEARNUSDCV2 0xEB801AB73E9A2A482aA48CaCA13B1954028F4c94
  const jarAddr = "0xEB801AB73E9A2A482aA48CaCA13B1954028F4c94";
  const jar = (await ethers.getContractAt("IJar", jarAddr)) as IJar;

  // fees 10000 = 10% because feesMax = 100000 and 10000 / 100000 = 0.1
  const fees = 10000;
  // UBQRate 10e18, if the UBQRate is 10 then 10/10000 = 0.001
  // 1UBQ gives you 0.001% of fee reduction so 100000 UBQ gives you 100%
  const UBQRate = ethers.utils.parseEther("100");
  // bonusYield  5000 = 50% 100 = 1% 10 = 0.1% 1 = 0.01%
  const bonusYield = 5000;
  const net = await ethers.provider.getNetwork();
  deployments.log(`Current chain ID: ${net.chainId}`);

  const [ubqAccount] = await ethers.getSigners();

  const adminAdr = await ubqAccount.getAddress();
  deployments.log(
    `*****
    adminAdr address :`,
    adminAdr,
    `
  `
  );

  deployments.log(`jar at:`, jar.address);
  const opts = {
    from: adminAdr,
    log: true,
  };

  const UBQ_MINTER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("UBQ_MINTER_ROLE"));
  if (mgrAdr.length === 0) {
    const mgr = await deployments.deploy("UbiquityAlgorithmicDollarManager", {
      args: [adminAdr],
      ...opts,
    });
    mgrAdr = mgr.address;
  }

  const mgrFactory = await ethers.getContractFactory("UbiquityAlgorithmicDollarManager");

  const manager: UbiquityAlgorithmicDollarManager = mgrFactory.attach(
    mgrAdr // mgr.address
  ) as UbiquityAlgorithmicDollarManager;
  deployments.log(`UbiquityAlgorithmicDollarManager at:`, manager.address);

  const yieldProxyFactory = await ethers.getContractFactory("YieldProxy");
  const yieldProxy = (await yieldProxyFactory.deploy(manager.address, jar.address, fees, UBQRate, bonusYield)) as YieldProxy;

  deployments.log("yieldProxy deployed at:", yieldProxy.address);
  // yieldProxy should have the UBQ_MINTER_ROLE to mint uAR
  const tx = await manager.connect(ubqAccount).grantRole(UBQ_MINTER_ROLE, yieldProxy.address);
  await tx.wait();

  // try to migrate test

  deployments.log(`
    That's all folks !
    `);
};
export default func;
func.tags = ["YieldProxy"];
