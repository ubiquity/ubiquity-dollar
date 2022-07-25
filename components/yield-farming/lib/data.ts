import { BigNumber, ethers } from "ethers";

import { IJar, YieldProxy } from "@/dollar-types";

const isDev = process.env.NODE_ENV == "development";
const debug = isDev;

const YP_TOKEN = "usdc";
const YP_DECIMALS = 6;

const toEtherNum = (n: BigNumber) => +n.toString() / 1e18;

type YieldProxyContracts = {
  yieldProxy: YieldProxy;
  jarUsdc: IJar;
};

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

export async function loadYieldProxyData(contracts: YieldProxyContracts): Promise<YieldProxyData> {
  const [bonusYieldBase, bonusYieldMax, depositFeeBase, depositFeeMax, ubqRate, ubqRateMax] = await Promise.all([
    contracts.yieldProxy.bonusYield(),
    contracts.yieldProxy.BONUS_YIELD_MAX(),
    contracts.yieldProxy.fees(),
    contracts.yieldProxy.FEES_MAX(),
    contracts.yieldProxy.ubqRate(),
    contracts.yieldProxy.UBQ_RATE_MAX(),
  ]);

  const depositFeeUbqMax = ethers.utils.parseEther("100").mul(ubqRateMax).div(ubqRate);

  const jarRatio = await contracts.jarUsdc.getRatio();

  const simulatedNewJarRatio = jarRatio; // isDev ? jarRatio.mul(BigNumber.from(107)).div(BigNumber.from(100)) : jarRatio;

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
  bonusYieldExtraPct: number;
  bonusYieldTotalPct: number;
  bonusYieldAmount: BigNumber;
  feeAmount: BigNumber;
  feePct: number;
  newAmount: BigNumber;
  uar: BigNumber;
  currentYieldPct: number;
};

export async function loadYieldProxyDepositInfo(yp: YieldProxyData, contracts: YieldProxyContracts, address: string): Promise<YieldProxyDepositInfo | null> {
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
  const feePct = yp.depositFeeBasePct - (toEtherNum(di.ubqAmount) / toEtherNum(yp.depositFeeUbqMax)) * yp.depositFeeBasePct;

  const depositInfo: YieldProxyDepositInfo = {
    amount: di.amount,
    newAmount: di.amount.sub(di.fee),
    uad: di.uadAmount,
    ubq: di.ubqAmount,
    jarYieldAmount,
    bonusYieldExtraPct: toEtherNum(di.bonusYield) / toEtherNum(yp.bonusYieldMax) - yp.bonusYieldBasePct,
    bonusYieldTotalPct: toEtherNum(di.bonusYield) / toEtherNum(yp.bonusYieldMax),
    bonusYieldAmount,
    feeAmount: feeIn18,
    feePct: feePct,
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
