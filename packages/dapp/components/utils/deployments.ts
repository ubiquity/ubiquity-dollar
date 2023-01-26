import fullArtifact from "@ubiquity/contracts/deployments.json";

export type deployed = typeof fullArtifact;
export type deployedChainId = keyof deployed;
export type deploymentContracts = deployed[deployedChainId]["contracts"];

export type deployedContractName = keyof deploymentContracts;
export type deployedContract = deploymentContracts[deployedContractName];
export type deployedContractAbi = deployedContract["abi"];

export const getDeployments = (chainId: deployedChainId, contractName: deployedContractName) => {
  const selectedDeployment = fullArtifact[chainId];
  return selectedDeployment.contracts[contractName];
};

// hard coded the following type because I couldn't figure out how to
// dynamically generate it based on the deployment artifact json file correctly

// export type AllDeployedContractNames =
//   | "Bonding"
//   | "BondingFormulas"
//   | "BondingShare"
//   | "BondingShareV2"
//   | "BondingV2"
//   | "CouponsForDollarsCalculator"
//   | "CurveUADIncentive"
//   | "DebtCoupon"
//   | "DebtCouponManager"
//   | "DollarMintingCalculator"
//   | "ExcessDollarsDistributor"
//   | "MasterChef"
//   | "MasterChefV2"
//   | "TWAPOracle"
//   | "UARForDollarsCalculator"
//   | "UbiquityAlgorithmicDollar"
//   | "UbiquityAlgorithmicDollarManager"
//   | "UbiquityAutoRedeem"
//   | "UbiquityFormulas"
//   | "UbiquityGovernance"
//   | "UbiquiStick"
//   | "TheUbiquityStickSale"
//   /* */ // below looks wrong, but it's what's in the artifact
//   | "Bonding"
//   | "BondingFormulas"
//   | "BondingShare"
//   | "BondingShareV2"
//   | "BondingV2"
//   | "CouponsForDollarsCalculator"
//   | "CurveUADIncentive"
//   | "DebtCoupon"
//   | "CreditNftManager"
//   | "DollarMintingCalculator"
//   | "ExcessDollarsDistributor"
//   | "MasterChef"
//   | "MasterChefV2"
//   | "TWAPOracle"
//   | "UARForDollarsCalculator"
//   | "UbiquityAlgorithmicDollar"
//   | "UbiquityAlgorithmicDollarManager"
//   | "UbiquityAutoRedeem"
//   | "UbiquityFormulas"
//   | "UbiquityGovernance"
//   | "UbiquiStick"
//   | "TheUbiquityStickSale";
