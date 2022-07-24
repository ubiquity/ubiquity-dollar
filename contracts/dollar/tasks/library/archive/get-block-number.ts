import "@nomiclabs/hardhat-waffle";
import { ActionType } from "hardhat/types";
module.exports = {
  description: "Task that returns the current block number",
  action:
    (): ActionType<any> =>
    async (_taskArgs, { ethers }) => {
      const blockNumber = await ethers.provider.getBlockNumber();
      console.log(`Current block number: ${blockNumber}`);
    },
};
