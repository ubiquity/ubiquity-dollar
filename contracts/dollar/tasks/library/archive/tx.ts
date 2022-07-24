import "@nomiclabs/hardhat-waffle";
import { ActionType } from "hardhat/types";

const params = { hash: "The transaction's hash" };

module.exports = {
  description: "Prints the detail for the transaction hash",
  params,
  action:
    (): ActionType<any> =>
    async (taskArgs: typeof params, { ethers }) => {
      const provider = ethers.providers.getDefaultProvider();
      let receipt = (await provider.getTransactionReceipt(taskArgs.hash)) as any;
      delete receipt.logsBloom as any;
      console.table(receipt);
    },
};
