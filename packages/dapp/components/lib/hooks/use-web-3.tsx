import { JsonRpcProvider, JsonRpcSigner, Web3Provider } from "@ethersproject/providers";
import { ConnectKitProvider, getDefaultClient } from "connectkit";
import { config } from "dotenv";
import getConfig from "next/config";
import { FC } from "react";
import { WagmiConfig, createClient, useAccount, useProvider, useSigner } from "wagmi";
import { hardhat, localhost, mainnet } from "wagmi/chains";
import { CoinbaseWalletConnector } from "wagmi/connectors/coinbaseWallet";
import { InjectedConnector } from "wagmi/connectors/injected";
import { MetaMaskConnector } from "wagmi/connectors/metaMask";
import { WalletConnectConnector } from "wagmi/connectors/walletConnect";
import { ChildrenShim } from "./children-shim-d";
const IS_DEV = process.env.NODE_ENV == "development";
const LOCAL_NODE_ADDRESS = "http://localhost:8545";
config();

const { publicRuntimeConfig } = getConfig();

const { NEXT_PUBLIC_JSON_RPC_URL, NEXT_PUBLIC_WALLET_CONNECT_ID } = publicRuntimeConfig;

export type PossibleProviders = Web3Provider | JsonRpcProvider | null;

export type Web3State = {
  metamaskInstalled: boolean;
  jsonRpcEnabled: boolean;
  providerMode: "none" | "metamask" | "jsonrpc";
  provider: PossibleProviders;
  connecting: boolean;
  walletAddress: null | string;
  signer?: JsonRpcSigner;
};

const metamaskInstalled = typeof window !== "undefined" ? !!window?.ethereum?.request : false;

const defaultChains = [mainnet, hardhat, localhost];

const client = createClient(
  getDefaultClient({
    chains: defaultChains,
    appName: "Ubiquity DAO",
    appDescription: "World's first scalable digital dollar",
    appIcon: "https://dao.ubq.fi/favicon.ico",
    appUrl: "https://dao.ubq.fi/",
    autoConnect: true,
    connectors: [
      new MetaMaskConnector({
        chains: defaultChains,
        options: {
          shimDisconnect: true,
          UNSTABLE_shimOnConnectSelectAccount: true,
        },
      }),
      new InjectedConnector({
        chains: defaultChains,
        options: {
          name: "Injected Wallet",
          getProvider: () => (typeof window !== "undefined" ? window.ethereum : undefined),
          shimDisconnect: true,
        },
      }),
      new CoinbaseWalletConnector({
        chains: defaultChains,
        options: {
          appName: "Ubiquity DAO",
          appLogoUrl: "https://dao.ubq.fi/favicon.ico",
          darkMode: true,
          headlessMode: true,
          jsonRpcUrl: NEXT_PUBLIC_JSON_RPC_URL,
        },
      }),
      new WalletConnectConnector({
        chains: defaultChains,
        options: {
          showQrModal: false,
          projectId: NEXT_PUBLIC_WALLET_CONNECT_ID,
          metadata: {
            name: "Ubiquity DAO",
            description: "World's first scalable digital dollar",
            url: "https://dao.ubq.fi/",
            icons: ["https://dao.ubq.fi/favicon.ico"],
          },
        },
      }),
    ],
  })
);

export const UseWeb3Provider: FC<ChildrenShim> = ({ children }) => {
  return (
    <WagmiConfig client={client}>
      <ConnectKitProvider
        theme="midnight"
        customTheme={{
          "--ck-body-background": "#000",
          "--ck-border-radius": "8px",
        }}
        mode="dark"
      >
        {children}
      </ConnectKitProvider>
    </WagmiConfig>
  );
};

const useWeb3 = (): Web3State => {
  const provider = useProvider();
  const { isConnecting, address } = useAccount();
  const { data: signer } = useSigner();

  return {
    metamaskInstalled,
    jsonRpcEnabled: IS_DEV,
    providerMode: "none",
    provider: provider as PossibleProviders,
    connecting: isConnecting,
    walletAddress: address as string,
    signer: signer as JsonRpcSigner,
  };
};

export default useWeb3;
