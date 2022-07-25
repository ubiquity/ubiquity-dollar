import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@typechain/hardhat";
import * as dotenv from "dotenv";
import "hardhat-deploy";
import "hardhat-gas-reporter";
import "solidity-coverage";
import type { HardhatNetworkAccountUserConfig, HardhatUserConfig } from "hardhat/types";

import { Wallet } from "ethers";
import "tsconfig-paths/register";
import "./tasks/index";

dotenv.config({ path: `../../.env` });

if (!process.env.API_KEY_ALCHEMY) {
  throw new Error("ENV Variable API_KEY_ALCHEMY not set!");
}

if (!process.env.MNEMONIC) {
  throw new Error("ENV Variable MNEMONIC not set!");
}

const accounts = [] as string[];

for (let i = 0; i <= 5; i++) {
  const wallet = Wallet.fromMnemonic(process.env.MNEMONIC, `m/44'/60'/0'/0/${i}`);
  accounts.push(wallet.privateKey);
}

const accountsHardhat: HardhatNetworkAccountUserConfig[] = accounts.map((account) => ({
  privateKey: account,
  balance: "2000000000000000000000",
}));

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  namedAccounts: {
    deployer: { default: 0, mainnet: 0 },
    minter: { default: 1, mainnet: 0 },
    tester1: { default: 2 },
    tester2: { default: 3 },
    random: { default: 4 },
    treasury: { default: 5, mainnet: 0 },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.9",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.4",
      },
    ],
  },
  networks: {
    hardhat: {
      loggingEnabled: false,
      accounts: accountsHardhat,
      initialBaseFeePerGas: 0,
      forking: {
        url: `https://eth-mainnet.alchemyapi.io/v2/${process.env.API_KEY_ALCHEMY}`,
      },
    },
    local: {
      chainId: 1,
      url: "http://0.0.0.0:8545",
    },
    mainnet: {
      chainId: 1,
      url: `https://eth-mainnet.alchemyapi.io/v2/${process.env.API_KEY_ALCHEMY}`,
      accounts,
    },
    rinkeby: {
      loggingEnabled: true,
      chainId: 4,
      url: `https://rinkeby.infura.io/v3/${process.env.API_KEY_ALCHEMY}`,
      accounts,
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.API_KEY_ETHERSCAN || "",
  },
  typechain: {
    outDir: "types",
    target: "ethers-v5",
  },
  paths: {
    sources: "contracts",
    deploy: "deploy",
    deployments: "deployments",
    tests: "tests",
    imports: "lib",
    cache: "artifacts/cache",
    artifacts: "artifacts",
  },
  mocha: {
    timeout: 1_000_000,
    bail: true,
  },
};

export default config;
