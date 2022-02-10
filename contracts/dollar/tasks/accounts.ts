import { task } from "hardhat/config";
import "@nomiclabs/hardhat-waffle";

// follows ETH/BTC's BIP 39 protocol
// https://iancoleman.io/bip39/
// and matches the one hardhat uses when using { accounts: { mnemonic }}
task("accounts", "prints the first few accounts of a mnemonic").setAction(
  async (_taskArgs, { ethers }) => {
    const accounts = await ethers.getSigners();
    accounts.forEach((account) => console.log(account.address));
  }
);
