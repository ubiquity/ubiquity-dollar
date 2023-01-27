import { deployedContractName } from "./deployments";

const nameUpgrades = {
  Bonding: "Staking",
  BondingFormulas: "StakingFormulas",
  BondingShare: "StakingToken",
  BondingShareV2: "StakingToken",
  BondingV2: "Staking",
  CouponsForDollarsCalculator: "CreditNftRedemptionCalculator",
  CurveUADIncentive: "CurveDollarIncentive",
  DebtCoupon: "CreditNft",
  DebtCouponManager: "CreditNftManager",
  DollarMintingCalculator: "DollarMintCalculator",
  ExcessDollarsDistributor: "DollarMintExcess",
  MasterChef: "UbiquityChef",
  MasterChefV2: "UbiquityChef",
  TWAPOracle: "TWAPOracleDollar3pool",
  UARForDollarsCalculator: "UARForDollarsCalculator",
  UbiquityAlgorithmicDollar: "UbiquityDollarToken",
  UbiquityAlgorithmicDollarManager: "UbiquityDollarManager",
  UbiquityAutoRedeem: "UbiquityCreditToken",
  UbiquityFormulas: "UbiquityFormulas",
  UbiquityGovernance: "UbiquityGovernanceToken",
  UbiquiStick: "UbiquiStick",
  TheUbiquityStickSale: "UbiquiStickSale",
};

// const unallocatedNames = [
//   "DirectGovernanceFarmer",
//   "SushiSwapPool",
//   "CreditClock",
//   "CreditRedemptionCalculator",
//   "Diamond",
//   "DiamondCutFacet",
//   "DiamondLoupeFacet",
//   "ManagerFacet",
//   "OwnershipFacet",
//   "Modifiers",
//   "DiamondInit",
//   "SimpleBond",
// ];

export function getKeyFromValue(contractName: string) {
  const keys = Object.keys(nameUpgrades);
  const key = keys.find((key: string) => {
    return (nameUpgrades as Record<string, string>)[key] === contractName;
  });
  if (!key) {
    throw new Error(`Could not find key for contract name: ${contractName}`);
  }
  return key as deployedContractName;
}
