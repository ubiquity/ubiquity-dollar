import { task } from "hardhat/config";
import "@nomiclabs/hardhat-waffle";

task("tx", "Prints the detail for the transaction hash")
  .addParam("hash", "The transaction's hash")
  .setAction(async (taskArgs: { hash: string }, { ethers }) => {
    await ethers.provider
      .getTransactionReceipt(taskArgs.hash)
      .then((receipt) => {
        console.log(`
        From: ${receipt.from}
        To: ${receipt.to}
        Status: ${receipt.status === 1 ? "Ok" : "Error"}
        BlockNumber: ${receipt.blockNumber}
        GasUsed: ${receipt.gasUsed.toString()}
        Confirmations: ${receipt.confirmations}`);
      });
  });
