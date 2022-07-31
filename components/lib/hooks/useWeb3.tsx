import { JsonRpcProvider, JsonRpcSigner, Web3Provider } from "@ethersproject/providers";
import { ethers } from "ethers";
import { createContext, useContext, useEffect, useState } from "react";
import useLocalStorage from "./useLocalStorage";

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
  signer: null | JsonRpcSigner;
};

type Web3Actions = {
  connectMetamask: () => Promise<void>;
  connectJsonRpc: (address: string) => Promise<void>;
  disconnect: () => Promise<void>;
};

const metamaskInstalled = typeof window !== "undefined" ? !!window?.ethereum?.request : false;
const DEFAULT_WEB3_STATE: Web3State = {
  metamaskInstalled,
  jsonRpcEnabled: IS_DEV,
  providerMode: "none",
  provider: null,
  connecting: false,
  walletAddress: null,
  signer: null,
};

const DEFAULT_WEB3_ACTIONS: Web3Actions = {
  connectMetamask: async () => {},
  connectJsonRpc: async () => {},
  disconnect: async () => {},
};

export const Web3Context = createContext<[Web3State, Web3Actions]>([DEFAULT_WEB3_STATE, DEFAULT_WEB3_ACTIONS]);

export const UseWeb3Provider: React.FC = ({ children }) => {
  const [storedWallet, setStoredWallet] = useLocalStorage<null | string>("storedWallet", null);
  const [storedProviderMode, setStoredProviderMode] = useLocalStorage<Web3State["providerMode"]>("storedProviderMode", "none");
  const [web3State, setWeb3State] = useState<Web3State>(DEFAULT_WEB3_STATE);

  useEffect(() => {
    if (storedProviderMode === "jsonrpc" && storedWallet) {
      connectJsonRpc(storedWallet);
    } else {
      connectMetamask();
    }
  }, []);

  async function connectMetamask() {
    if (metamaskInstalled) {
      const newProvider = new ethers.providers.Web3Provider(window.ethereum);
      setWeb3State({ ...web3State, connecting: true });
      const addresses = (await newProvider.send("eth_requestAccounts", [])) as string[];
      if (addresses.length > 0) {
        console.log("Connected wallet ", addresses[0]);
        const newWalletAddress = addresses[0];
        const newSigner = newProvider.getSigner(newWalletAddress);
        setStoredWallet(newWalletAddress);
        setStoredProviderMode("metamask");
        setWeb3State({
          ...web3State,
          connecting: false,
          providerMode: "metamask",
          provider: newProvider,
          walletAddress: newWalletAddress,
          signer: newSigner,
        });
      } else {
        alert("No accounts found");
        setWeb3State({ ...web3State, connecting: false });
      }
    }
  }

  async function connectJsonRpc(newWalletAddress: string) {
    setWeb3State({ ...web3State, connecting: true });
    const newProvider = new ethers.providers.JsonRpcProvider(LOCAL_NODE_ADDRESS);
    await newProvider.send("hardhat_impersonateAccount", [newWalletAddress]);
    const newSigner = newProvider.getSigner(newWalletAddress);
    setStoredWallet(newWalletAddress);
    setStoredProviderMode("jsonrpc");
    setWeb3State({ ...web3State, connecting: false, providerMode: "jsonrpc", provider: newProvider, walletAddress: newWalletAddress, signer: newSigner });
  }

  async function disconnect() {
    setWeb3State({ ...web3State, walletAddress: null, signer: null });
  }

  return <Web3Context.Provider value={[web3State, { connectMetamask, connectJsonRpc, disconnect }]}>{children}</Web3Context.Provider>;
};

const useWeb3 = () => useContext(Web3Context);

export default useWeb3;
