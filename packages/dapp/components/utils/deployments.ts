import fullArtifact from "@ubiquity/contracts/deployments.json";

export type deployed = typeof fullArtifact;
export type deployedChainId = keyof deployed;
export type deployedContractName = keyof deployed[deployedChainId]["contracts"];
export type deployedContractAbi = deployed[deployedChainId]["contracts"][deployedContractName]["abi"];

// export type deployedContractAddresses = deployed[deployedChainId]["contracts"][deployedContractName]["address"];

// const readDeployments = () => fullArtifact as deployments;

export const getDeployments = (chainId: deployedChainId, contractName: deployedContractName): { address: string; abi: deployedContractAbi } => {
  const selectedDeployment = fullArtifact[chainId];
  return selectedDeployment.contracts[contractName];
};
