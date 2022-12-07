import { JsonRpcProvider, JsonRpcSigner, Web3Provider } from "@ethersproject/providers";
import { useAccount, useProvider, useSigner } from "wagmi";
import { WagmiConfig, createClient, chain } from "wagmi";
import { ConnectKitProvider, getDefaultClient } from "connectkit";
import { FC } from "react";
import { ChildrenShim } from "./children-shim";

const IS_DEV = process.env.NODE_ENV == "development";
const LOCAL_NODE_ADDRESS = "http://localhost:8545";

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

const client = createClient(
  getDefaultClient({
    chains: [chain.mainnet, chain.hardhat, chain.localhost],
    autoConnect: true,
    appName: "Ubiquity",
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
      >
        {children}
      </ConnectKitProvider>
    </WagmiConfig>
  );
};

const useWeb3 = (): [Web3State] => {
  const provider = useProvider();
  const { isConnecting, address } = useAccount();
  const { data: signer } = useSigner();

  return [
    {
      metamaskInstalled,
      jsonRpcEnabled: IS_DEV,
      providerMode: "none",
      provider: provider as PossibleProviders,
      connecting: isConnecting,
      walletAddress: address as string,
      signer: signer as JsonRpcSigner,
    },
  ];
};

export default useWeb3;
