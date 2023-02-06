import { BigNumber, ethers } from "ethers";

export const formatMwei = (n: BigNumber, round = 1e5): string => {
  return (Math.round(+ethers.utils.formatUnits(n, "mwei") * round) / round).toString();
};

export const formatEther = (n: BigNumber, round = 1e5): string => {
  return (Math.round(+ethers.utils.formatEther(n) * round) / round).toString();
};
