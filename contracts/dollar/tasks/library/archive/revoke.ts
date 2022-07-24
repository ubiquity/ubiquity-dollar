import "@nomiclabs/hardhat-waffle";
import { ActionType } from "hardhat/types";
import { UbiquityAlgorithmicDollarManager } from "../../../artifacts/types/UbiquityAlgorithmicDollarManager";

const params = { receiver: "The address that will be revoked", manager: "The address of uAD Manager" };

module.exports = {
  description: "revoke Minter Burner role of an address",
  params,
  action:
    (): ActionType<any> =>
    async (taskArgs: typeof params, { ethers }) => {
      const net = await ethers.provider.getNetwork();

      if (net.name === "hardhat") {
        console.warn(
          "You are running the faucet task with Hardhat network, which" +
            "gets automatically created and destroyed every time. Use the Hardhat" +
            " option '--network localhost'"
        );
      }
      console.log(`net chainId: ${net.chainId}  `);

      const UBQ_MINTER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("UBQ_MINTER_ROLE"));
      const UBQ_BURNER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("UBQ_BURNER_ROLE"));

      const manager = (await ethers.getContractAt("UbiquityAlgorithmicDollarManager", taskArgs.manager)) as UbiquityAlgorithmicDollarManager;

      const isMinter = await manager.hasRole(UBQ_MINTER_ROLE, taskArgs.receiver);
      console.log(`${taskArgs.receiver} is minter ?:${isMinter ? "true" : "false"}`);

      const isBurner = await manager.hasRole(UBQ_BURNER_ROLE, taskArgs.receiver);
      console.log(`${taskArgs.receiver} is burner ?:${isBurner ? "true" : "false"}`);

      if (isMinter) {
        const tx = await manager.revokeRole(UBQ_MINTER_ROLE, taskArgs.receiver);
        await tx.wait();
        console.log(`Minter role revoked`);
      }
      if (isBurner) {
        const tx = await manager.revokeRole(UBQ_BURNER_ROLE, taskArgs.receiver);
        await tx.wait();
        console.log(`Burner role revoked`);
      }
    },
};
