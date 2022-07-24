import "@nomiclabs/hardhat-waffle";
import { ActionType } from "hardhat/types";

module.exports = {
  description: "Prints the current chain ID",
  action:
    (): ActionType<any> =>
    async (_taskArgs, { ethers }) => {
      const net = await ethers.provider.getNetwork();
      console.log(`Current chain ID: ${net.chainId}`);
    },
};
