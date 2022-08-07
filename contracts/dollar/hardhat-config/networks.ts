import { HardhatUserConfig } from "hardhat/config";

const gasPrice = 60000000000;

export default function networks(accounts: { mnemonic: string; }, { MAINNET_PROVIDER_URL, ROPSTEN_PROVIDER_URL, RINKEBY_PROVIDER_URL, API_KEY_ALCHEMY, UBQ_ADMIN }: EnvironmentVariables) {

  const forking = {
    url: MAINNET_PROVIDER_URL || `https://eth-mainnet.alchemyapi.io/v2/${API_KEY_ALCHEMY || ""}`,
    blockNumber: 13252206,
  };

  return {
    localhost: {
      url: "http://0.0.0.0:8545",
      forking,
      hardfork: "london",
      accounts,
      initialBaseFeePerGas: 0,
    },
    hardhat: {
      forking,
      hardfork: "london",
      accounts,
      initialBaseFeePerGas: 0,
    },
    ropsten: {
      url: ROPSTEN_PROVIDER_URL || `https://eth-ropsten.alchemyapi.io/v2/${API_KEY_ALCHEMY}`,
      accounts,
      gasPrice,
    },
    rinkeby: {
      url: RINKEBY_PROVIDER_URL || `https://eth-rinkeby.alchemyapi.io/v2/${API_KEY_ALCHEMY}`,
      accounts,
      gasPrice,
    },
    mainnet: {
      url: MAINNET_PROVIDER_URL || `https://eth-mainnet.alchemyapi.io/v2/${API_KEY_ALCHEMY}`,
      accounts: UBQ_ADMIN ? [UBQ_ADMIN] : accounts,
      gasPrice,
    },
  } as HardhatUserConfig["networks"]
}

interface EnvironmentVariables {
  MAINNET_PROVIDER_URL: string | undefined;
  ROPSTEN_PROVIDER_URL: string | undefined;
  RINKEBY_PROVIDER_URL: string | undefined;
  API_KEY_ALCHEMY: string | undefined;
  UBQ_ADMIN: string | undefined;
}
