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
import { colorizeText } from "./tasks/utils/console-colors";

if (fs.existsSync(path.join(__dirname, "artifacts/types"))) {
  import("./tasks/index");
} else {
  console.warn("Tasks loading skipped until compilation artifacts are available");
}

dotenv.config({ path: path.join(__dirname, "../../.env") });
const { MNEMONIC, UBQ_ADMIN, API_KEY_ALCHEMY, REPORT_GAS } = process.env;

const accounts = { mnemonic: "test test test test test test test test test test test junk" }; // use default accounts

if (!MNEMONIC) {
  warn("MNEMONIC environment variable unset");
} else {
  accounts.mnemonic = MNEMONIC;
}

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
    ubq: {
      default: "0xefC0e701A824943b469a694aC564Aa1efF7Ab7dd", //  without UBQ => impersonate
      mainnet: 0, // use default account 0 with UBQ (of same address !) on mainnet
    },
    whaleAddress: "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2",
    tester: "0x89eae71b865a2a39cba62060ab1b40bbffae5b0d",
    sablier: "0xA4fc358455Febe425536fd1878bE67FfDBDEC59a",
    DAI: "0x6B175474E89094C44Da98b954EedeAC495271d0F",
    USDC: "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48",
    USDT: "0xdAC17F958D2ee523a2206206994597C13D831ec7",
    curve3CrvBasePool: "0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7",
    curve3CrvToken: "0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490",
    curveFactory: "0x0959158b6040D32d04c301A72CBFD6b39E21c9AE",
    curveWhaleAddress: "0xC2872ab688400940d5a6041599b3F7de20730d49",
    daiWhaleAddress: "0x16463c0fdB6BA9618909F5b120ea1581618C1b9E",
    sushiMultiSig: "0x9a8541Ddf3a932a9A922B607e9CF7301f1d47bD1",
    UbqWhaleAddress: "0xa53A6fE2d8Ad977aD926C485343Ba39f32D3A3F6",
    MasterChefAddress: "0x8fFCf9899738e4633A721904609ffCa0a2C44f3D",
    MetaPoolAddress: "0x20955cb69ae1515962177d164dfc9522feef567e",
    BondingAddress: "0x831e3674Abc73d7A3e9d8a9400AF2301c32cEF0C",
    BondingV2Address: "0xdAC17F958D2ee523a2206206994597C13D831ec7", // FAKE ADDRESS, TO BE REPLACED AFTER V2 DEPLOYMENT
    UbiquityAlgorithmicDollarManagerAddress: "0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98",
    jarUSDCAddr: "0xEB801AB73E9A2A482aA48CaCA13B1954028F4c94",
    jarYCRVLUSDaddr: "0x4fFe73Cf2EEf5E8C8E0E10160bCe440a029166D2",
    strategyYearnUsdcV2: "0xEecEE2637c7328300846622c802B2a29e65f3919",
    usdcWhaleAddress: "0x72A53cDBBcc1b9efa39c834A540550e23463AAcB",
    pickleControllerAddr: "0x6847259b2B3A4c17e7c43C54409810aF48bA5210",
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
      accounts: UBQ_ADMIN ? [UBQ_ADMIN] : accounts,
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
    coinmarketcap: getKey("COINMARKETCAP"),
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: getKey("ETHERSCAN"),
  },
};

export default config;

export function getAlchemyRpc(network: "mainnet" | "ropsten" | "rinkeby"): string {
  // This will try and resolve alchemy key related issues
  // first it will read the key value
  // if no value found, then it will attempt to load the .env from above to the .env in the current folder
  // if that fails, then it will throw an error and allow the developer to rectify the issue
  if (process.env.API_KEY_ALCHEMY?.length) {
    return `https://eth-${network}.alchemyapi.io/v2/${process.env.API_KEY_ALCHEMY}`;
  } else {
    throw new Error("Please set the API_KEY_ALCHEMY environment variable to your Alchemy API key");
  }
}

export function getKey(keyName: "ETHERSCAN" | "COINMARKETCAP") {
  const PREFIX = "API_KEY_";
  const ENV_KEY = PREFIX.concat(keyName);
  if (process.env[ENV_KEY]) {
    return process.env[ENV_KEY] as string;
  } else {
    warn(`Please set the ${ENV_KEY} environment variable to your ${keyName} API key`);
  }
}

export function warn(message: string) {
  console.warn(colorizeText(`\t⚠ ${message}`, "fgYellow"));
}
