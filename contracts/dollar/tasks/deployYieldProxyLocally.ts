import { task } from "hardhat/config";
import "@nomiclabs/hardhat-waffle";
import { ERC1155Ubiquity, ERC20 } from "../artifacts/types";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";
import { BondingShareV2 } from "../artifacts/types/BondingShareV2";
import { YieldProxy } from "../artifacts/types/YieldProxy";
import { IJar } from "../artifacts/types/IJar";

const NETWORK_ADDRESS = "http://localhost:8545";
const accountWithWithdrawableBond =
  "0x0000CE08fa224696A819877070BF378e8B131ACF";

task(
  "deployYieldProxyLocally",
  "Deploy YieldProxy to the current hardhat running node"
)
  .addOptionalParam("manager", "The address of uAD Manager")
  .setAction(
    async (
      taskArgs: { receiver: string | null; manager: string | null },
      { ethers, getNamedAccounts }
    ) => {
      const net = await ethers.provider.getNetwork();
      console.log(`net chainId: ${net.chainId}  `);

      // Gotta use this provider otherwise impersonation doesn't work
      // https://github.com/nomiclabs/hardhat/issues/1226#issuecomment-924352129
      const provider = new ethers.providers.JsonRpcProvider(NETWORK_ADDRESS);

      const {
        UbiquityAlgorithmicDollarManagerAddress: namedManagerAddress,
        ubq: namedTreasuryAddress,
        jarUSDCAddr,
        // curve3CrvToken: namedCurve3CrvAddress,
      } = await getNamedAccounts();

      const managerAddress = taskArgs.manager || namedManagerAddress;
      const [firstAccount] = await ethers.getSigners();
      const receiverAddress = taskArgs.receiver || firstAccount.address;

      const manager = (await ethers.getContractAt(
        "UbiquityAlgorithmicDollarManager",
        managerAddress
      )) as UbiquityAlgorithmicDollarManager;

      const jar = (await ethers.getContractAt("IJar", jarUSDCAddr)) as IJar;
      const yieldProxy = (await (
        await ethers.getContractFactory("YieldProxy")
      ).deploy(
        manager.address,
        jar.address,
        10000,
        ethers.utils.parseEther("100"),
        5000
      )) as YieldProxy;
      await yieldProxy.deployTransaction.wait();

      await provider.send("hardhat_impersonateAccount", [namedTreasuryAddress]);
      const treasuryAccount = provider.getSigner(namedTreasuryAddress);

      const UBQ_MINTER_ROLE = ethers.utils.keccak256(
        ethers.utils.toUtf8Bytes("UBQ_MINTER_ROLE")
      );
      await manager
        .connect(treasuryAccount)
        .grantRole(UBQ_MINTER_ROLE, yieldProxy.address);

      console.log("Yield proxy address: ", yieldProxy.address);
    }
  );
