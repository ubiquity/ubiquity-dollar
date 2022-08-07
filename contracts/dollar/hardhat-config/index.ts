
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import * as dotenv from "dotenv";
import fs from "fs";
import "hardhat-deploy";
import "hardhat-gas-reporter";
import { HardhatUserConfig } from "hardhat/types";
import path from "path";
import "solidity-coverage";
import gasReporter from "./gasReporter";

import namedAccounts from './named-accounts';
import networks from './networks';
import solidity from './solidity';
import { getKey } from './utils/getKey';
import { warn } from "./utils/warn";

// WAIT UNTIL ARTIFACTS ARE GENERATED BEFORE RUNNING TASKS.
if (fs.existsSync(path.join(__dirname, "artifacts/types"))) {
  import("../tasks/index");
} else {
  console.warn("Tasks loading skipped until compilation artifacts are available");
}

// LOAD .ENV
const pathToDotEnv = path.join(__dirname, "../../../.env");
fs.stat(pathToDotEnv, function (err, stats) {
  if (err) throw err
})
dotenv.config({ path: pathToDotEnv });

// READ .ENV
const {
  MNEMONIC,
  UBQ_ADMIN,
  API_KEY_ALCHEMY,
  REPORT_GAS,
  MAINNET_PROVIDER_URL,
  ROPSTEN_PROVIDER_URL,
  RINKEBY_PROVIDER_URL
} = process.env;

// USE TEST/DEFAULT ACCOUNTS IF MNEMONIC ENVIRONMENT VARIABLE UNSET
const accounts = { mnemonic: "test test test test test test test test test test test junk" };

if (!MNEMONIC) {
  warn("MNEMONIC environment variable unset");
} else {
  accounts.mnemonic = MNEMONIC;
}

// THE HARDHAT CONFIG
export default {
  solidity,
  namedAccounts,
  mocha: { timeout: 1000000, },
  networks: networks(accounts, { MAINNET_PROVIDER_URL, ROPSTEN_PROVIDER_URL, RINKEBY_PROVIDER_URL, API_KEY_ALCHEMY, UBQ_ADMIN }),
  typechain: { outDir: "artifacts/types", target: "ethers-v5", },
  gasReporter: gasReporter(REPORT_GAS),
  etherscan: { apiKey: getKey("ETHERSCAN"), },
} as HardhatUserConfig;
