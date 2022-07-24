import "@nomiclabs/hardhat-waffle";
import { ActionType } from "hardhat/types";

module.exports = {
  description: "prints the first few accounts in ethers signers",
  action:
    (): ActionType<any> =>
    async (_taskArgs, { ethers }) => {
      const accounts = await ethers.getSigners();
      accounts.forEach((account) => console.log(account.address));
    },
};
