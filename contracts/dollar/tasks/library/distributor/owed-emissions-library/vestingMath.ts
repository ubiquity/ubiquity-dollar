import { warn } from "../../../../hardhat.config";
interface VestingMath {
  investorAllocationPercentage: number;
  totalSupplyCached: number;
}

export function vestingMath({ investorAllocationPercentage, totalSupplyCached }: VestingMath) {
  // below comments written on 7 june 2022
  // investorAllocationPercentage = 0.1
  const may2022 = 1651363200000;
  const may2024 = 1714521600000;

  const msTotal = may2024 - may2022; // 63158400000
  const msSinceStart = Date.now() - may2022; // 3177932875;
  let percentVested = msSinceStart / msTotal; // 0.05031686799

  if (percentVested > 1) {
    percentVested = 1;
    warn(`Vesting completed, capping percentVested to 100%`);
  }

  const shareOfTotalSupply = totalSupplyCached * investorAllocationPercentage;

  const investorShouldGet = shareOfTotalSupply * percentVested;
  return investorShouldGet; // 18,487.0939406307
}
