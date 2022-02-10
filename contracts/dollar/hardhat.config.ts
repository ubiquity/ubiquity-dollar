import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import * as dotenv from "dotenv";
import "hardhat-deploy";
import "hardhat-deploy-ethers";
import "hardhat-gas-reporter";
import "hardhat-typechain";
import { HardhatUserConfig } from "hardhat/config";
import "solidity-coverage";
import fs from "fs";
import path from "path";

if (fs.existsSync(path.join(__dirname, "artifacts/types"))) {
  import("./tasks/index");
} else {
  console.warn(
    "Tasks loading skipped until compilation artifacts are available"
  );
}

dotenv.config();
const {
  MNEMONIC,
  UBQ,
  ALCHEMY_API_KEY,
  ETHERSCAN_API_KEY,
  REPORT_GAS,
  COINMARKETCAP_API_KEY,
} = process.env;

const mnemonic = `${
  MNEMONIC || "test test test test test test test test test test test junk"
}`;

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
    UbiquityAlgorithmicDollarManagerAddress:
      "0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98",
    jarUSDCAddr: "0xEB801AB73E9A2A482aA48CaCA13B1954028F4c94",
    jarYCRVLUSDaddr: "0x4fFe73Cf2EEf5E8C8E0E10160bCe440a029166D2",
    strategyYearnUsdcV2: "0xEecEE2637c7328300846622c802B2a29e65f3919",
    usdcWhaleAddress: "0x72A53cDBBcc1b9efa39c834A540550e23463AAcB",
    pickleControllerAddr: "0x6847259b2B3A4c17e7c43C54409810aF48bA5210",
  },

  /*   paths: {
    deploy: "./scripts/deployment",
    deployments: "./deployments",
    sources: "./contracts",
    tests: "./tests",
    cache: "./cache",
    artifacts: "./artifacts",
  }, */
  networks: {
    localhost: {
      url: `http://127.0.0.1:8545`,
      forking: {
        url: `https://eth-mainnet.alchemyapi.io/v2/${
          process.env.ALCHEMY_API_KEY || ""
        }`,
        blockNumber: 13252206,
      },
      accounts,
      hardfork: "london",
      initialBaseFeePerGas: 0,
    },
    hardhat: {
      forking: {
        url: `https://eth-mainnet.alchemyapi.io/v2/${
          process.env.ALCHEMY_API_KEY || ""
        }`,
        blockNumber: 13252206,
      },
      accounts,
      hardfork: "london",
      initialBaseFeePerGas: 0,
    },
    mainnet: {
      url: `https://eth-mainnet.alchemyapi.io/v2/${
        process.env.ALCHEMY_API_KEY || ""
      }`,
      accounts: UBQ ? [UBQ] : accounts,
      gasPrice: 60000000000,
    },
    ropsten: {
      gasPrice: 60000000000,
      url: `https://eth-ropsten.alchemyapi.io/v2/${
        process.env.ALCHEMY_API_KEY || ""
      }`,
      accounts,
    },
    rinkeby: {
      gasPrice: 60000000000,
      url: `https://eth-rinkeby.alchemyapi.io/v2/${ALCHEMY_API_KEY || ""}`,
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
    coinmarketcap: `${COINMARKETCAP_API_KEY || ""}`,
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: `${ETHERSCAN_API_KEY || ""}`,
  },
};

export default config;
