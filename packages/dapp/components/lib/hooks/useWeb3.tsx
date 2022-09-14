/* eslint-disable no-debugger */
import { JsonRpcProvider, JsonRpcSigner, Web3Provider } from "@ethersproject/providers";
import { ethers } from "ethers";
import { createContext, useContext, useEffect, useState } from "react";
import { ChildrenShim } from "./children-shim";
import useLocalStorage from "./useLocalStorage";
import WalletConnect from "@walletconnect/client";
import QRCodeModal from "@walletconnect/qrcode-modal";
import WalletConnectProvider from "@walletconnect/web3-provider";
import getConfig from "next/config";
const { publicRuntimeConfig } = getConfig();

const IS_DEV = process.env.NODE_ENV == "development";
const LOCAL_NODE_ADDRESS = "http://localhost:8545";

export type PossibleProviders = Web3Provider | JsonRpcProvider | null;

export type Web3State = {
  metamaskInstalled: boolean;
  jsonRpcEnabled: boolean;
  providerMode: "none" | "metamask" | "jsonrpc" | "walletconnect";
  provider: PossibleProviders;
  connecting: boolean;
  walletAddress: null | string;
  signer: null | JsonRpcSigner;
  connector: null | WalletConnect;
};

type Web3Actions = {
  connectMetaMask: () => Promise<void>;
  connectJsonRpc: (address: string) => Promise<void>;
  connectWalletConnect: () => Promise<void>;
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
  connector: null,
};

const DEFAULT_WEB3_ACTIONS: Web3Actions = {
  connectMetaMask: async () => {},
  connectWalletConnect: async () => {},
  connectJsonRpc: async () => {},
  disconnect: async () => {},
};

export const Web3Context = createContext<[Web3State, Web3Actions]>([DEFAULT_WEB3_STATE, DEFAULT_WEB3_ACTIONS]);

export const UseWeb3Provider: React.FC<ChildrenShim> = ({ children }) => {
  const [storedWallet, setStoredWallet] = useLocalStorage<null | string>("storedWallet", null);
  const [storedProviderMode, setStoredProviderMode] = useLocalStorage<Web3State["providerMode"]>("storedProviderMode", "none");
  const [web3State, setWeb3State] = useState<Web3State>(DEFAULT_WEB3_STATE);

  useEffect(() => {
    if (storedProviderMode) {
      if ("jsonrpc" == storedProviderMode) {
        if (storedWallet) {
          connectJsonRpc(storedWallet);
        }
      } else if ("metamask" == storedProviderMode) {
        connectMetaMask();
      }
    }
  }, []);

  async function connectWalletConnect() {
    const bridge = "https://bridge.walletconnect.org";

    // create new connector
    const connector = new WalletConnect({ bridge, qrcodeModal: QRCodeModal });

    // check if already connected
    if (!connector.connected) {
      // create new session
      await connector.createSession();
    }

    connector.on("connect", async (error, payload) => {
      const { chainId, accounts } = payload.params[0];
      const newWalletAddress = accounts[0];

      const newProvider = new WalletConnectProvider({
        infuraId: process.env.API_KEY_ALCHEMY,
      });

      const web3Provider = new ethers.providers.Web3Provider(newProvider);
      const newSigner = web3Provider.getSigner(newWalletAddress);
      setStoredWallet(newWalletAddress);
      setStoredProviderMode("walletconnect");

      setWeb3State({
        ...web3State,
        connecting: true,
        providerMode: "walletconnect",
        walletAddress: newWalletAddress,
        provider: web3Provider,
        signer: newSigner,
        connector: connector,
      });
    });
  }

  async function connectMetaMask() {
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
    if (web3State.connector) {
      web3State.connector.killSession();
    }
    setWeb3State({ ...web3State, walletAddress: null, signer: null });
  }

  return <Web3Context.Provider value={[web3State, { connectMetaMask, connectWalletConnect, connectJsonRpc, disconnect }]}>{children}</Web3Context.Provider>;
};

const useWeb3 = () => useContext(Web3Context);

export default useWeb3;
