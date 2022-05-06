import { ethers } from "ethers";

export type Web3Provider = ethers.providers.Web3Provider | null;

function getProvider(): ethers.providers.Web3Provider | null {
  const metamaskInstalled = typeof window !== "undefined" ? !!(window as any)?.ethereum?.request : false;
  console.log("Metamask: ", metamaskInstalled ? "Installed" : "Not installed");
  return metamaskInstalled ? new ethers.providers.Web3Provider((window as any).ethereum) : null;
}

let web3Provider: Web3Provider;
const useWeb3Provider = (): Web3Provider => {
  return typeof web3Provider === "undefined" ? (web3Provider = getProvider()) : web3Provider;
};

export default useWeb3Provider;
