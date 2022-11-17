import { MetaMaskInpageProvider } from "@metamask/providers";
import * as ethers from "ethers";

declare global {
  interface Window {
    ethereum?: MetaMaskInpageProvider;
    web3: ethers.providers.ExternalProvider;
  }
}
declare module "*.svg" {
  const value: React.StatelessComponent<React.SVGAttributes<SVGElement>>;
  export default value;
}
