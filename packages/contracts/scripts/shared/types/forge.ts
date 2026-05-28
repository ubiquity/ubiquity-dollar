export type ForgeArguments = {
  name: string;
  network: string;
  rpcUrl: string;
  privateKey: string;
  contractInstance: string;
  constructorArguments: string[];
  etherscanApiKey?: string;
};
