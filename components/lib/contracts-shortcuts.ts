import { BigNumber, ethers } from "ethers";

import { ERC1155Ubiquity, ERC20 } from "@/dollar-types";

import { performTransaction } from "./utils";

export async function ensureERC20Allowance(
  logName: string,
  contract: ERC20,
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

export async function ensureERC1155Allowance(
  logName: string,
  contract: ERC1155Ubiquity,
  signer: ethers.providers.JsonRpcSigner,
  spender: string
): Promise<boolean> {
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

// export async function logBondingUbqInfo(contracts: Contracts) {
//   const reserves = await contracts.ugovUadPair.getReserves();
//   const ubqReserve = +reserves.reserve0.toString();
//   const uadReserve = +reserves.reserve1.toString();
//   const ubqPrice = uadReserve / ubqReserve;
//   console.log("uAD-UBQ Pool", uadReserve, ubqReserve);
//   console.log("UBQ Price", ubqPrice);
//   const ubqPerBlock = await contracts.masterChef.uGOVPerBlock();
//   const ubqMultiplier = await contracts.masterChef.uGOVmultiplier();
//   const ugovDivider = toNum(await contracts.masterChef.uGOVDivider());

//   console.log("UBQ per block", toEtherNum(ubqPerBlock));
//   console.log("UBQ Multiplier", toEtherNum(ubqMultiplier));
//   const actualUbqPerBlock = toEtherNum(ubqPerBlock.mul(ubqMultiplier).div(`${1e18}`));
//   console.log("Actual UBQ per block", actualUbqPerBlock);
//   console.log("Extra UBQ per block to treasury", actualUbqPerBlock / ugovDivider);
//   const blockCountInAWeek = toNum(await contracts.bonding.blockCountInAWeek());
//   console.log("Block count in a week", blockCountInAWeek);

//   const ubqPerWeek = actualUbqPerBlock * blockCountInAWeek;
//   console.log("UBQ Minted per week", ubqPerWeek);
//   console.log("Extra UBQ minted per week to treasury", ubqPerWeek / ugovDivider);

//   const DAYS_IN_A_YEAR = 365.2422;
//   const totalShares = toEtherNum(await contracts.masterChef.totalShares());
//   console.log("Total Bonding Shares", totalShares);
//   const usdPerWeek = ubqPerWeek * ubqPrice;
//   const usdPerDay = usdPerWeek / 7;
//   const usdPerYear = usdPerDay * DAYS_IN_A_YEAR;
//   console.log("USD Minted per day", usdPerDay);
//   console.log("USD Minted per week", usdPerWeek);
//   console.log("USD Minted per year", usdPerYear);
//   const usdAsLp = 0.7562534324;
//   const bigNumberOneUsdAsLp = ethers.utils.parseEther(usdAsLp.toString());

//   const bondingDiscountMultiplier = await contracts.bonding.bondingDiscountMultiplier();
//   const sharesResults = await Promise.all(
//     [1, 50, 100, 208].map(async (i) => {
//       const weeks = BigNumber.from(i.toString());
//       const shares = toEtherNum(await contracts.ubiquityFormulas.durationMultiply(bigNumberOneUsdAsLp, weeks, bondingDiscountMultiplier));
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
