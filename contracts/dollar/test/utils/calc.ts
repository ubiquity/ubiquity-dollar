import { BigNumber } from "ethers";
import { ethers } from "hardhat";
import { Big, RoundingMode } from "big.js";

// to have decent precision
Big.DP = 35;
// to avoid exponential notation
Big.PE = 105;
Big.NE = -35;

// returns (twapPrice - 1) * uADTotalSupply
export function calcDollarsToMint(uADTotalSupply: string, twapPrice: string): BigNumber {
  const uADSupply = new Big(uADTotalSupply);
  const price = new Big(twapPrice);
  const one = new Big(ethers.utils.parseEther("1").toString());
  return BigNumber.from(price.sub(one).mul(uADSupply.div(one)).round(0, RoundingMode.RoundDown).toString());
}

// returns  multiplier * ( 1.05 / (1 + abs( 1 - price ) ) )
export function calculateUGOVMultiplier(multiplier: string, price: string): BigNumber {
  // should be in wei
  const onez5 = new Big(ethers.utils.parseEther("1.05").toString());
  const one = new Big(ethers.utils.parseEther("1").toString());

  const mult = new Big(multiplier);
  const p = new Big(price);
  const priceDiff = one.sub(p).abs();

  return BigNumber.from(
    mult
      .mul(onez5.div(one.add(priceDiff)))
      .round(0, RoundingMode.RoundDown)
      .toString()
  );
}

// returns amount +  (1- TWAP_Price)%.
export function calculateIncentiveAmount(amountInWEI: string, curPriceInWEI: string): BigNumber {
  // should be in ETH
  const one = new Big(ethers.utils.parseEther("1").toString());
  const amount = new Big(amountInWEI);
  // returns amount +  (1- TWAP_Price)%.
  return BigNumber.from(one.sub(curPriceInWEI).mul(amount.div(one)).round(0, RoundingMode.RoundDown).toString());
}

// returns true if amountA - AmountB < precision. precision is in decimal
export function isAmountEquivalent(amountA: string, amountB: string, precision?: string): boolean {
  const a = new Big(amountA);
  const b = new Big(amountB);
  const delta = new Big(precision || "0.0000000000000000000000000000000001");

  const diff = a.gt(b) ? a.div(b).sub(1) : b.div(a).sub(1);
  // assert expected presision
  return diff.lte(delta);
}

// returns shares / totalShares * totalToken (in wei)
export function calcShareInToken(totalShares: string, shares: string, totalToken: string): BigNumber {
  // calculate  shares / totalShares * totalToken
  const totShares = new Big(totalShares);
  const userShares = new Big(shares);
  const totToken = new Big(totalToken);

  return BigNumber.from(userShares.div(totShares).mul(totToken).round(0, RoundingMode.RoundDown).toString());
}

// returns amount * percentage (in wei)
export function calcPercentage(amount: string, percentage: string): BigNumber {
  // calculate amount * percentage
  const value = new Big(amount);
  const one = new Big(ethers.utils.parseEther("1").toString());
  const percent = new Big(percentage).div(one);
  return BigNumber.from(value.mul(percent).round(0, RoundingMode.RoundDown).toString());
}

// returns amount * 1 / (1-debt/totalsupply)²
export function calcPremium(amount: string, uADTotalSupply: string, totalDebt: string): BigNumber {
  const one = new Big(1);
  const uADTotSupply = new Big(uADTotalSupply);
  const TotDebt = new Big(totalDebt);
  const amountToPremium = new Big(amount);
  // premium =  amount * 1 / (1-debt/totalsupply)²
  const prem = amountToPremium.mul(one.div(one.sub(TotDebt.div(uADTotSupply)).pow(2)));
  return BigNumber.from(prem.round(0, RoundingMode.RoundDown).toString());
}

// returns amount *  (blockHeightDebt/currentBlockHeight)^coef
export function calcUARforDollar(amount: string, blockHeightDebt: string, currentBlockHeight: string, coefficient: string): BigNumber {
  const one = new Big(ethers.utils.parseEther("1").toString());
  const tmpCoef = new Big(coefficient);
  const coef = tmpCoef.div(one);
  const blockNum = new Big(currentBlockHeight);
  const debtHeight = new Big(blockHeightDebt);
  const amounInETH = new Big(ethers.utils.formatEther(amount));
  // uAR amount = UAD amount *  (blockHeightDebt/currentBlockHeight)^coef
  const res = amounInETH.toNumber() * (debtHeight.toNumber() / blockNum.toNumber()) ** coef.toNumber();
  let resBig = new Big(res);
  resBig = resBig.mul(one);
  return BigNumber.from(resBig.round(0, RoundingMode.RoundDown).toString());
}
