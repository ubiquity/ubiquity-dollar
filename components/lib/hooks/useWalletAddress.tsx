import React, { useContext, useState, createContext } from "react";

import useWeb3Provider from "./useWeb3Provider";

export type WalletAddress = null | string;
export const WalletAddressContext = createContext<[WalletAddress, boolean, () => void]>([null, false, () => {}]);

export const WalletAddressContextProvider: React.FC = ({ children }) => {
  const web3Provider = useWeb3Provider();
  const [walletAddress, setWalletAddress] = useState<WalletAddress>(null);
  const [connecting, setConnecting] = useState(false);

  async function connectWallet() {
    if (!connecting) {
      if (web3Provider) {
        setConnecting(true);
        const addresses = (await web3Provider.send("eth_requestAccounts", [])) as string[];
        if (addresses.length > 0) {
          console.log("Connected wallet ", addresses[0]);
          setWalletAddress(addresses[0]);
        } else {
          alert("No accounts found");
        }

        setConnecting(false);
      } else {
        alert("MetaMask is not installed!");
        console.error("MetaMask is not installed, cannot connect wallet");
      }
    }
  }

  return <WalletAddressContext.Provider value={[walletAddress, connecting, connectWallet]}> {children} </WalletAddressContext.Provider>;
};

const useWalletAddress = () => useContext(WalletAddressContext);

export default useWalletAddress;
