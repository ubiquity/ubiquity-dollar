import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ethers";
import "@typechain/hardhat";
import * as dotenv from "dotenv";
import "hardhat-deploy";
import "hardhat-gas-reporter";
import "solidity-coverage";
import { HardhatUserConfig } from "hardhat/types";

import fs from "fs";
import path from "path";

if (fs.existsSync(path.join(__dirname, "artifacts/types"))) {
  import("./tasks/index");
} else {
  console.warn("Tasks loading skipped until compilation artifacts are available");
}

dotenv.config({ path: path.join(__dirname, "../../.env") });
const { MNEMONIC, UBQ, API_KEY_ALCHEMY, API_KEY_ETHERSCAN, REPORT_GAS, API_KEY_COINMARKETCAP } = process.env;

const mnemonic = `${MNEMONIC || "test test test test test test test test test test test junk"}`;

const accounts = {
  // use default accounts
  mnemonic,
};

const config: HardhatUserConfig = {
  solidity: {
    compilers: [
      {
        version: "0.8.3",
        settings: {
          optimizer: {
            enabled: true,
            runs: 800,
          },
          metadata: {
            // do not include the metadata hash, since this is machine dependent
            // and we want all generated code to be deterministic
            // https://docs.soliditylang.org/en/v0.7.6/metadata.html
            bytecodeHash: "none",
          },
        },
      },
    ],
  },

  mocha: {
    timeout: 1000000,
  },
  namedAccounts: {
    deployer: { default: 0 },
    alice: { default: 1 },
    bob: { default: 2 }
  },
  networks: {
    localhost: {
      url: "http://0.0.0.0:8545",
      forking: {
        url: process.env.MAINNET_PROVIDER_URL || `https://eth-mainnet.alchemyapi.io/v2/${process.env.API_KEY_ALCHEMY || ""}`,
        blockNumber: 13252206,
      },
      accounts,
      hardfork: "london",
      initialBaseFeePerGas: 0,
    },
    hardhat: {
      forking: {
        url: process.env.MAINNET_PROVIDER_URL || `https://eth-mainnet.alchemyapi.io/v2/${process.env.API_KEY_ALCHEMY || ""}`,
        blockNumber: 15173327,
      },
      accounts,
      hardfork: "london",
      initialBaseFeePerGas: 0,
    },
    mainnet: {
      url: process.env.MAINNET_PROVIDER_URL || `https://eth-mainnet.alchemyapi.io/v2/${process.env.API_KEY_ALCHEMY || ""}`,
      accounts: UBQ ? [UBQ] : accounts,
      gasPrice: 60000000000,
    },
    ropsten: {
      gasPrice: 60000000000,
      url: process.env.ROPSTEN_PROVIDER_URL || `https://eth-ropsten.alchemyapi.io/v2/${process.env.API_KEY_ALCHEMY || ""}`,
      accounts,
    },
    rinkeby: {
      gasPrice: 60000000000,
      url: process.env.RINKEBY_PROVIDER_URL || `https://eth-rinkeby.alchemyapi.io/v2/${API_KEY_ALCHEMY || ""}`,
      accounts,
    },
  },
  typechain: {
    outDir: "artifacts/types",
    target: "ethers-v5",
  },
  gasReporter: {
    enabled: REPORT_GAS === "true",
    currency: "USD",
    gasPrice: 60,
    onlyCalledMethods: true,
    coinmarketcap: `${API_KEY_COINMARKETCAP || ""}`,
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: `${API_KEY_ETHERSCAN || ""}`,
  },
};

export default config;
