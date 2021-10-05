import { ethers, BigNumber } from "ethers";
import { Contracts } from "../../contracts";
import { ERC1155Ubiquity, ERC20 } from "../../contracts/artifacts/types";
import { erc1155BalanceOf } from "./utils";
import { EthAccount } from "./types";
import { performTransaction } from "./utils";

const isDev = process.env.NODE_ENV == "development";
const debug = isDev;

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

const YP_TOKEN = "usdc";
const YP_DECIMALS = 6;

export type YieldProxyData = {
  token: typeof YP_TOKEN;
  decimals: typeof YP_DECIMALS;
  depositFeeMax: BigNumber;
  depositFeeBase: BigNumber; // depositFee % = depositFeeBase / depositFeeMax
  depositFeeBasePct: number; // depositFeeBase / depositFeeMax
  depositFeeUbqMax: BigNumber; // If UBQ = this => depositFee = 0%
  bonusYieldMax: BigNumber;
  bonusYieldBase: BigNumber; // bonusYield % = bonusYieldBase / bonusYieldMax
  bonusYieldBasePct: number; // bonusYieldBase / bonusYieldMax
  bonusYieldMaxPct: number; // bonusYieldBase / bonusYieldMax
  bonusYieldUadMaxPct: number; // Hardcoded at 0.5 of main amount // If uAD = this => bonusYield = bonusYieldMax
  jarRatio: BigNumber;
};

export async function loadYieldProxyData(contracts: Contracts): Promise<YieldProxyData> {
  const [bonusYieldBase, bonusYieldMax, depositFeeBase, depositFeeMax] = await Promise.all([
    contracts.yieldProxy.bonusYield(),
    contracts.yieldProxy.bonusYieldMax(),
    contracts.yieldProxy.fees(),
    contracts.yieldProxy.feesMax(),
  ]);
  const depositFeeUbqMax = await contracts.yieldProxy.UBQRateMax();

  const jarRatio = await contracts.jarUsdc.getRatio();

  const simulatedNewJarRatio = isDev ? jarRatio.mul(BigNumber.from(107)).div(BigNumber.from(100)) : jarRatio;

  const di: YieldProxyData = {
    token: YP_TOKEN,
    decimals: YP_DECIMALS,
    depositFeeMax,
    depositFeeBase,
    depositFeeBasePct: depositFeeBase.toNumber() / depositFeeMax.toNumber(),
    depositFeeUbqMax,
    bonusYieldMax,
    bonusYieldBase,
    bonusYieldBasePct: bonusYieldBase.toNumber() / bonusYieldMax.toNumber(),
    bonusYieldMaxPct: 1,
    bonusYieldUadMaxPct: 0.5,
    jarRatio: simulatedNewJarRatio,
  };
  if (debug) {
    console.log(`YieldProxy ${di.token.toUpperCase()} (${di.decimals} decimals)`);
    console.log(`  .depositFeeBasePct: ${di.depositFeeBasePct * 100}%`);
    console.log(`  .depositFeeUbqMax: if UBQ = ${ethers.utils.formatEther(di.depositFeeUbqMax)} => fee = 0%`);
    console.log(`  .bonusYieldBasePct: ${di.bonusYieldBasePct * 100}%`);
    console.log(`  .bonusYieldUadMaxPct: if uAD = ${di.bonusYieldUadMaxPct * 100}% of ${di.token.toUpperCase()} amount => bonusYield = 100%`);
    console.log(`  .jarRatio ${ethers.utils.formatEther(jarRatio)}`);
    if (isDev) {
      console.log(`  .jarRatio (SIMULATED) ${ethers.utils.formatEther(di.jarRatio)}`);
    }
  }
  return di;
}

export type YieldProxyDepositInfo = {
  amount: BigNumber;
  uad: BigNumber;
  ubq: BigNumber;
  jarYieldAmount: BigNumber;
  bonusYieldAmount: BigNumber;
  feeAmount: BigNumber;
  newAmount: BigNumber;
  uar: BigNumber;
  currentYieldPct: number;
};

export async function loadYieldProxyDepositInfo(yp: YieldProxyData, contracts: Contracts, address: string): Promise<YieldProxyDepositInfo | null> {
  const di = await (async () => {
    const [amount, shares, uadAmount, ubqAmount, fee, ratio, bonusYield] = await contracts.yieldProxy.getInfo(address);
    return { amount, shares, uadAmount, ubqAmount, fee, ratio, bonusYield };
  })();

  if (di.amount.eq(0)) {
    return null;
  }

  const amountIn18 = yp.decimals < 18 ? di.amount.mul(Math.pow(10, 18 - yp.decimals)) : di.amount;
  const feeIn18 = yp.decimals < 18 ? di.fee.mul(Math.pow(10, 18 - yp.decimals)) : di.fee;

  const jarYieldAmount = amountIn18.mul(yp.jarRatio).div(di.ratio).sub(amountIn18);
  const bonusYieldAmount = jarYieldAmount.gt(0) ? jarYieldAmount.mul(di.bonusYield).div(yp.bonusYieldMax) : BigNumber.from(0);
  const currentYieldPct = toEtherNum(amountIn18.add(jarYieldAmount).add(bonusYieldAmount)) / toEtherNum(amountIn18) - 1;

  const depositInfo: YieldProxyDepositInfo = {
    amount: di.amount,
    newAmount: di.amount.sub(di.fee),
    uad: di.uadAmount,
    ubq: di.ubqAmount,
    jarYieldAmount,
    bonusYieldAmount,
    feeAmount: feeIn18,
    uar: jarYieldAmount.add(bonusYieldAmount).add(feeIn18),
    currentYieldPct,
  };

  if (debug) {
    console.log(`YieldProxyDeposit ${yp.token.toUpperCase()} (${yp.decimals} decimals)`);
    console.log(`  .amount: `, ethers.utils.formatUnits(depositInfo.amount, yp.decimals));
    console.log(`  .newAmount:`, ethers.utils.formatUnits(depositInfo.newAmount, yp.decimals));
    console.log("  .uad:", ethers.utils.formatEther(depositInfo.uad));
    console.log("  .ubq:", ethers.utils.formatEther(depositInfo.ubq));
    console.log("  .jarYieldAmount:", ethers.utils.formatEther(jarYieldAmount));
    console.log("  .bonusYieldAmount:", ethers.utils.formatEther(bonusYieldAmount));
    console.log("  .feeAmount:", ethers.utils.formatEther(depositInfo.feeAmount));
    console.log("  .uar:", ethers.utils.formatEther(depositInfo.uar));
    console.log(`  .currentYieldPct: ${depositInfo.currentYieldPct * 100}%`);
  }

  return depositInfo;
}

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
