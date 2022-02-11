import { task } from "hardhat/config";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";
import pressAnyKey from "../utils/flow";

task(
  "excessdollardistribution",
  "excessdollardistribution deployment"
).setAction(
  async (
    taskArgs: { amount: string; pushhigher: boolean },
    { ethers, deployments }
  ) => {
    const net = await ethers.provider.getNetwork();
    const accounts = await ethers.getSigners();
    const adminAdr = await accounts[0].getAddress();

    const debtCouponMgrAdr = "0x432120Ad63779897A424f7905BA000dF38A74554";
    console.log(`---account addr:${adminAdr}  `);

    console.log(`net chainId: ${net.chainId}  `);

    if (net.chainId === 31337) {
      console.warn("You are running the   task with Hardhat network");
    }

    const manager = (await ethers.getContractAt(
      "UbiquityAlgorithmicDollarManager",
      "0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98"
    )) as UbiquityAlgorithmicDollarManager;

    const mgrExcessDollarsDistributor =
      await manager.getExcessDollarsDistributor(debtCouponMgrAdr);

    console.warn(
      `we will deploy a new ExcessDollarDistributor
      and replace the existing one :${mgrExcessDollarsDistributor}
      for debtManager ${debtCouponMgrAdr} `
    );

    await pressAnyKey("Press any key if you are sure you want to continue ...");
    console.log(`will deploy a new excessDollarDistributor `);
    const opts = {
      from: adminAdr,
      skipIfAlreadyDeployed: false,
      log: true,
    };

    const exDollaDistrib = await deployments.deploy(
      "ExcessDollarsDistributor",
      {
        args: [manager.address],
        ...opts,
      }
    );
    console.log(
      `new ExcessDollarsDistributor address:${exDollaDistrib.address} `
    );
    console.log(`will set the address to the manager `);
    const tx = await manager.setExcessDollarsDistributor(
      debtCouponMgrAdr,
      exDollaDistrib.address
    );

    console.log(`  waiting for confirmation`);
    const receipt = tx.wait(1);

    console.log(
      `tx ${(await receipt).status === 0 ? "FAIL" : "SUCCESS"}
        hash:${tx.hash}

        `
    );
    const newExcessDollarsDistributor =
      await manager.getExcessDollarsDistributor(debtCouponMgrAdr);
    console.log(`new ExcessDollarDistributor ${newExcessDollarsDistributor} for debtManager ${debtCouponMgrAdr}
                setup into the manager
        `);
  }
);
