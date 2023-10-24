import { BigNumber, ethers, Contract } from "ethers";

import { performTransaction } from "./utils";

export async function ensureERC20Allowance(
  logName: string,
  contract: Contract,
  amount: BigNumber,
  signer: ethers.providers.JsonRpcSigner,
  spender: string,
  decimals = 18
): Promise<boolean> {
  const signerAddress = await signer.getAddress();
  const allowance1 = await contract.allowance(signerAddress, spender);
  console.log(`Current ${logName} allowance: ${ethers.utils.formatUnits(allowance1, decimals)} | Requesting: ${ethers.utils.formatUnits(amount, decimals)}`);
  if (allowance1.lt(amount)) {
    if (!(await performTransaction(contract.connect(signer).approve(spender, amount)))) {
      return false;
    }
    const allowance2 = await contract.allowance(signerAddress, spender);
    console.log(`New ${logName} allowance: `, ethers.utils.formatUnits(allowance2, decimals));
  }

  return true;
}

export async function ensureERC1155Allowance(logName: string, contract: Contract, signer: ethers.providers.JsonRpcSigner, spender: string): Promise<boolean> {
  const signerAddress = await signer.getAddress();
  const isAllowed = await contract.isApprovedForAll(signerAddress, spender);
  console.log(`${logName} isAllowed: `, isAllowed);
  if (!isAllowed) {
    if (!(await performTransaction(contract.connect(signer).setApprovalForAll(spender, true)))) {
      return false;
    }
    const isAllowed2 = await contract.isApprovedForAll(signerAddress, spender);
    console.log(`New ${logName} isAllowed: `, isAllowed2);
  }

  return true;
}

// const toEtherNum = (n: BigNumber) => +n.toString() / 1e18;
// const toNum = (n: BigNumber) => +n.toString();

// export async function logStakingGovernanceInfo(contracts: Contracts) {
//   const reserves = await contracts.ugovDollarPair.getReserves();
//   const governanceReserve = +reserves.reserve0.toString();
//   const dollarReserve = +reserves.reserve1.toString();
//   const governancePrice = dollarReserve / governanceReserve;
//   console.log("DOLLAR-GOVERNANCE Pool", dollarReserve, governanceReserve);
//   console.log("GOVERNANCE Price", governancePrice);
//   const governancePerBlock = await contracts.masterChef.uGOVPerBlock();
//   const governanceMultiplier = await contracts.masterChef.uGOVmultiplier();
//   const ugovDivider = toNum(await contracts.masterChef.uGOVDivider());

//   console.log("GOVERNANCE per block", toEtherNum(governancePerBlock));
//   console.log("GOVERNANCE Multiplier", toEtherNum(governanceMultiplier));
//   const actualGovernancePerBlock = toEtherNum(governancePerBlock.mul(governanceMultiplier).div(`${1e18}`));
//   console.log("Actual GOVERNANCE per block", actualGovernancePerBlock);
//   console.log("Extra GOVERNANCE per block to treasury", actualGovernancePerBlock / ugovDivider);
//   const blockCountInAWeek = toNum(await contracts.staking.blockCountInAWeek());
//   console.log("Block count in a week", blockCountInAWeek);

//   const governancePerWeek = actualGovernancePerBlock * blockCountInAWeek;
//   console.log("GOVERNANCE Minted per week", governancePerWeek);
//   console.log("Extra GOVERNANCE minted per week to treasury", governancePerWeek / ugovDivider);

//   const DAYS_IN_A_YEAR = 365.2422;
//   const totalShares = toEtherNum(await contracts.masterChef.totalShares());
//   console.log("Total Staking Shares", totalShares);
//   const usdPerWeek = governancePerWeek * governancePrice;
//   const usdPerDay = usdPerWeek / 7;
//   const usdPerYear = usdPerDay * DAYS_IN_A_YEAR;
//   console.log("USD Minted per day", usdPerDay);
//   console.log("USD Minted per week", usdPerWeek);
//   console.log("USD Minted per year", usdPerYear);
//   const usdAsLp = 0.7460387929;
//   const bigNumberOneUsdAsLp = ethers.utils.parseEther(usdAsLp.toString());

//   const stakingDiscountMultiplier = await contracts.staking.stakingDiscountMultiplier();
//   const sharesResults = await Promise.all(
//     [1, 50, 100, 208].map(async (i) => {
//       const weeks = BigNumber.from(i.toString());
//       const shares = toEtherNum(await contracts.ubiquityFormulas.durationMultiply(bigNumberOneUsdAsLp, weeks, stakingDiscountMultiplier));
//       return [i, shares];
//     })
//   );
//   const apyResultsDisplay = sharesResults.map(([weeks, shares]) => {
//     const rewardsPerWeek = (shares / totalShares) * usdPerWeek;
//     const weeklyYield = rewardsPerWeek * 100;
//     const yearlyYield = (rewardsPerWeek / 7) * DAYS_IN_A_YEAR * 100;
//     return { lp: 1, weeks: weeks, shares: shares / usdAsLp, weeklyYield: `${weeklyYield.toPrecision(2)}%`, yearlyYield: `${yearlyYield.toPrecision(4)}%` };
//   });
//   console.table(apyResultsDisplay);
// }
