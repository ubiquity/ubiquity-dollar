import { task } from "hardhat/config";
import { getContractAddress } from "@ethersproject/address";

task("contract-address", "Print future contract address.")
  .addOptionalParam("from", "from")
  .addOptionalParam("nonce", "nonce")
  .setAction(async (taskArgs: any, { ethers }) => {
    const [owner] = await ethers.getSigners();
    const from = taskArgs.from || owner.address;
    const nonce = taskArgs.nonce || (await owner.getTransactionCount());

    const futureAddress = getContractAddress({ from, nonce });

    console.log(`${futureAddress}   <= ${from}::${nonce}`);
  });
