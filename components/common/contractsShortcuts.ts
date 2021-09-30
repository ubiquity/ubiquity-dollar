import { ethers, BigNumber } from "ethers";
import { Contracts } from "../../contracts";
import { ERC1155Ubiquity } from "../../contracts/artifacts/types";
import { erc1155BalanceOf } from "./utils";
import { EthAccount } from "./types";

export interface Balances {
  uad: BigNumber;
  crv: BigNumber;
  uad3crv: BigNumber;
  uar: BigNumber;
  ubq: BigNumber;
  bondingShares: BigNumber;
  debtCoupon: BigNumber;
}

// Load the account balances in a single parallel operation
export async function accountBalances(account: EthAccount, contracts: Contracts): Promise<Balances> {
  const [uad, crv, uad3crv, uar, ubq, debtCoupon, bondingShares] = await Promise.all([
    contracts.uad.balanceOf(account.address),
    contracts.crvToken.balanceOf(account.address),
    contracts.metaPool.balanceOf(account.address),
    contracts.uar.balanceOf(account.address),
    contracts.ugov.balanceOf(account.address),
    erc1155BalanceOf(account.address, contracts.debtCouponToken),
    erc1155BalanceOf(account.address, (contracts.bondingToken as unknown) as ERC1155Ubiquity),
  ]);
  return {
    uad,
    crv,
    uad3crv,
    uar,
    ubq,
    debtCoupon,
    bondingShares,
  };
}

const toEtherNum = (n: BigNumber) => +n.toString() / 1e18;
const toNum = (n: BigNumber) => +n.toString();

export async function logBondingUbqInfo(contracts: Contracts) {
  const reserves = await contracts.ugovUadPair.getReserves();
  const ubqReserve = +reserves.reserve0.toString();
  const uadReserve = +reserves.reserve1.toString();
  const ubqPrice = uadReserve / ubqReserve;
  console.log("uAD-UBQ Pool", uadReserve, ubqReserve);
  console.log("UBQ Price", ubqPrice);
  const ubqPerBlock = await contracts.masterChef.uGOVPerBlock();
  const ubqMultiplier = await contracts.masterChef.uGOVmultiplier();
  const ugovDivider = toNum(await contracts.masterChef.uGOVDivider());

  console.log("UBQ per block", toEtherNum(ubqPerBlock));
  console.log("UBQ Multiplier", toEtherNum(ubqMultiplier));
  const actualUbqPerBlock = toEtherNum(ubqPerBlock.mul(ubqMultiplier).div(`${1e18}`));
  console.log("Actual UBQ per block", actualUbqPerBlock);
  console.log("Extra UBQ per block to treasury", actualUbqPerBlock / ugovDivider);
  const blockCountInAWeek = toNum(await contracts.bonding.blockCountInAWeek());
  console.log("Block count in a week", blockCountInAWeek);

  const ubqPerWeek = actualUbqPerBlock * blockCountInAWeek;
  console.log("UBQ Minted per week", ubqPerWeek);
  console.log("Extra UBQ minted per week to treasury", ubqPerWeek / ugovDivider);

  const DAYS_IN_A_YEAR = 365.2422;
  const totalShares = toEtherNum(await contracts.masterChef.totalShares());
  console.log("Total Bonding Shares", totalShares);
  const usdPerWeek = ubqPerWeek * ubqPrice;
  const usdPerDay = usdPerWeek / 7;
  const usdPerYear = usdPerDay * DAYS_IN_A_YEAR;
  console.log("USD Minted per day", usdPerDay);
  console.log("USD Minted per week", usdPerWeek);
  console.log("USD Minted per year", usdPerYear);
  const usdAsLp = 0.75;
  const bigNumberOneUsdAsLp = ethers.utils.parseEther(usdAsLp.toString());

  const bondingDiscountMultiplier = await contracts.bonding.bondingDiscountMultiplier();
  const sharesResults = await Promise.all(
    [1, 50, 100, 208].map(async (i) => {
      const weeks = BigNumber.from(i.toString());
      const shares = toEtherNum(await contracts.ubiquityFormulas.durationMultiply(bigNumberOneUsdAsLp, weeks, bondingDiscountMultiplier));
      return [i, shares];
    })
  );
  const apyResultsDisplay = sharesResults.map(([weeks, shares]) => {
    const rewardsPerWeek = (shares / totalShares) * usdPerWeek;
    const weeklyYield = rewardsPerWeek * 100;
    const yearlyYield = (rewardsPerWeek / 7) * DAYS_IN_A_YEAR * 100;
    return { lp: 1, weeks: weeks, shares: shares / usdAsLp, weeklyYield: `${weeklyYield.toPrecision(2)}%`, yearlyYield: `${yearlyYield.toPrecision(4)}%` };
  });
  console.table(apyResultsDisplay);
}
