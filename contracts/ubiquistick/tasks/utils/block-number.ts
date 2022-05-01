import { task } from "hardhat/config";
import "@nomiclabs/hardhat-waffle";

task("block-number", "Prints the current block number").setAction(async (_taskArgs, { ethers }) => {
  await ethers.provider.getBlockNumber().then((blockNumber) => {
    console.log(`Current block number: ${blockNumber}`);
  });
});
