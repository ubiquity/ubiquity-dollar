import "@nomiclabs/hardhat-waffle";
import { ActionType } from "hardhat/types";
import * as fs from "fs";

module.exports = {
  description: "gets the code of an address",
  positionalParam: {
    address: ["The address of the contract"],
  },
  optionalParam: {
    path: ["The path to store the contract", `contract.evm`],
  },
  action:
    (): ActionType<any> =>
    async (taskArgs: { address: string; path: string }, { ethers }) => {
      const { address, path } = taskArgs;
      const { provider } = ethers;
      const code = await provider.getCode(address);
      const bytes = Buffer.from(code.replace(`0x`, ``), `hex`);
      console.log(`address`, address);
      console.log(`contract size`, bytes.byteLength, bytes.slice(0, 256));
      fs.writeFileSync(path, bytes);
    },
};
