import { ethers } from "ethers";

const formatter = new Intl.NumberFormat("en-US");
const formatterFixed = new Intl.NumberFormat("en-US", { minimumFractionDigits: 2 });
export const format = (n: number) => formatter.format(n);
export const formatFixed = (n: number) => formatterFixed.format(n);
export const round = (n: number) => Math.round(n * 100) / 100;

export const multiplierFromRatio = (ratio: ethers.BigNumber): number => {
  return parseInt(ratio.toString()) / 1_000_000_000;
};

export const apyFromRatio = (ratio: ethers.BigNumber): number | null => {
  const VESTING_DAYS = 5;
  const multiplier = multiplierFromRatio(ratio);
  return multiplier > 1 ? multiplier ** (365 / VESTING_DAYS) - 1 : null;
};
