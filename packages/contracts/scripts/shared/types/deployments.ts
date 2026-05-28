export type DeploymentResult = {
  deployedTo: string;
  deployer: string;
  transactionHash: string;
};

export type ContractDeployments = Record<string, { address: string; deployer: string; transactionHash: string; abi: any }>;
export type DeploymentsForChain = { name: string; chainId: string; contracts: ContractDeployments };
export type ChainDeployments = Record<string, DeploymentsForChain>;
