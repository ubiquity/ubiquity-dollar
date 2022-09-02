import { MetaMaskInpageProvider } from "@metamask/providers";

declare global {
  interface Window {
    ethereum?: MetaMaskInpageProvider;
  }
}
declare module "*.svg" {
  const value: React.StatelessComponent<React.SVGAttributes<SVGElement>>;
  export default value;
}
