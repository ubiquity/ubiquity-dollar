import type {
  HardhatUserConfig,
  HardhatNetworkAccountUserConfig,
  HardhatNetworkHDAccountsUserConfig
} from "hardhat/types";

import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-waffle";
import "hardhat-deploy";
import "hardhat-deploy-ethers";
import "hardhat-gas-reporter";
import "solidity-coverage";

import "@typechain/hardhat";
import "tsconfig-paths/register";
import "./tasks/index";
import dotenv from "dotenv";
import { Wallet } from "ethers";

dotenv.config();
if (!process.env.ALCHEMY_API_KEY) {
  throw new Error("ENV Variable ALCHEMY_API_KEY not set!");
}

const accounts = [process.env.DEPLOYER_PRIVATE_KEY || ""];
for (let i = 1; i <= 5; i++) accounts.push(Wallet.createRandom().privateKey);
const accountsHardhat: HardhatNetworkAccountUserConfig[] = accounts.map((account) => ({
  privateKey: account || "",
  balance: "2000000000000000000000"
}));

const ubq = "0xefC0e701A824943b469a694aC564Aa1efF7Ab7dd";

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  namedAccounts: {
    deployer: { default: 0, mainnet: 0 },
    minter: { default: 1, mainnet: 0 },
    tester1: { default: 2 },
    tester2: { default: 3 },
    random: { default: 4 },
    treasury: { default: 5, mainnet: 0 }
  },
  solidity: {
    compilers: [
      {
        version: "0.8.9",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.8.4"
      }
    ]
  },
  networks: {
    hardhat: {
      loggingEnabled: false,
      accounts: accountsHardhat,
      initialBaseFeePerGas: 0,
      forking: {
        url: `https://eth-mainnet.alchemyapi.io/v2/${process.env.ALCHEMY_API_KEY}`
      }
    },
    local: {
      chainId: 1,
      url: "http://127.0.0.1:8545"
    },
    mainnet: {
      chainId: 1,
      url: `https://eth-mainnet.alchemyapi.io/v2/${process.env.ALCHEMY_API_KEY}`,
      accounts
    },
    rinkeby: {
      loggingEnabled: true,
      chainId: 4,
      url: `https://rinkeby.infura.io/v3/${process.env.ALCHEMY_API_KEY}`,
      accounts
    }
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD"
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY || ""
  },
  typechain: {
    outDir: "types",
    target: "ethers-v5"
  },
  paths: {
    sources: "contracts",
    deploy: "deploy",
    deployments: "deployments",
    tests: "tests",
    imports: "lib",
    cache: "artifacts/cache",
    artifacts: "artifacts"
  },
  mocha: {
    timeout: 1_000_000,
    bail: true
  }
};

export default config;
