import "@nomiclabs/hardhat-waffle";
import { ActionType } from "hardhat/types";

interface TaskArgs {
  mnemonic: string;
}

module.exports = {
  description: "prints the first few accounts of a mnemonic",
  params: { mnemonic: "The mnemonic used for BIP39 key derivation: See https://iancoleman.io/bip39" },
  action:
    (): ActionType<any> =>
    async (taskArgs: TaskArgs, { ethers }) => {
      const { mnemonic } = taskArgs;
      if (!mnemonic) {
        throw new Error(`Missing task argument --mnemonic `);
      }
      const masterKey = await Promise.resolve(ethers.utils.HDNode.fromMnemonic(mnemonic));
      // "m/44'/60'/0'/0/0" first account
      const getPathForIndex = (index: number) => `m/44'/60'/0'/0/${index}`;
      Array.from({ length: 5 }).forEach((_, index) => {
        const key = masterKey.derivePath(getPathForIndex(index));
        console.log(`Key ${getPathForIndex(index)}: ${key.address} (PK: ${key.publicKey}) (sk: ${key.privateKey})`);
      });
    },
};
