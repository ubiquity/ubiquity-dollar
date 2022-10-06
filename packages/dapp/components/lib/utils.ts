import { PossibleProviders } from "@/lib/hooks/useWeb3";
import { BigNumber, Contract, ContractTransaction, ethers } from "ethers";
import { useEffect } from "react";

export function logGas(txDone: ethers.ContractReceipt) {
  console.log(`Gas used with 100 gwei / gas:${ethers.utils.formatEther(txDone.gasUsed.mul(ethers.utils.parseUnits("100", "gwei")))}`);
}

export function useAsyncInit(cb: () => Promise<unknown>) {
  useEffect(() => {
    (async () => {
      await cb();
    })();
  }, []);
}

export async function performTransaction(transaction: Promise<ContractTransaction>) {
  // try {
  const tx = await transaction;
  const txR = await tx.wait();
  logGas(txR);
  return true;
  // } catch (e) {
  //   console.error("Transaction error", e);
  //   throw e;
  // }
  // return false;
}

export async function erc1155BalanceOf(addr: string, erc1155UbiquityCtr: Contract): Promise<BigNumber> {
  const treasuryIds = await erc1155UbiquityCtr.holderTokens(addr);

  const balanceOfs = treasuryIds.map((id: string) => {
    return erc1155UbiquityCtr.balanceOf(addr, id);
  });
  const balances = await Promise.all(balanceOfs);
  let fullBalance = BigNumber.from(0);
  if (balances.length > 0) {
    fullBalance = balances.reduce((prev, cur) => {
      return prev.add(cur);
    });
  }
  return fullBalance;
}

export const constrainNumber = (num: number, min: number, max: number): number => {
  if (num < min) return min;
  else if (num > max) return max;
  else return num;
};

export const constrainStringNumber = (val: string, min: number, max: number): string => {
  const num = parseFloat(val);
  if (isNaN(num)) return val;
  else if (num < min) return min.toString();
  else if (num > max) return max.toString();
  else return val;
};

export const getNetworkName = (provider: NonNullable<PossibleProviders>): string => {
  let networkName = "";
  switch (provider.network?.chainId) {
    case 1:
      networkName = "Mainnet";
      break;
    case 3:
      networkName = "Ropsten Test Network";
      break;
    case 4:
      networkName = "Rinkeby Test Network";
      break;
    case 5:
      networkName = "Goerli Test Network";
      break;
    case 42:
      networkName = "Kovan Test Network";
      break;
    default:
      networkName = "Unknown Network";
      break;
  }
  return networkName;
};

export const formatTimeDiff = (diff: number) => {
  const day = 24 * 60 * 60 * 1000;
  const hour = 60 * 60 * 1000;
  const minute = 60 * 1000;
  const second = 1000;
  const days = Math.ceil(diff / day);
  if (days > 1) {
    return `${days} days`;
  }
  const hours = Math.ceil(diff / hour);
  if (hours > 1) {
    return `${hours} hours`;
  }
  const minutes = Math.ceil(diff / minute);
  if (minutes > 1) {
    return `${minutes} minutes`;
  }
  const seconds = Math.ceil(diff / second);
  return `${seconds} seconds`;
};

export const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

// Coin Addresses
export const uCR_ADDRESS = "0x5894cfebfdedbe61d01f20140f41c5c49aedae97";
export const uAD_ADDRESS = "0x0F644658510c95CB46955e55D7BA9DDa9E9fBEc6";
export const USDC_ADDRESS = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48";
export const DAI_ADDRESS = "0x6b175474e89094c44da98b954eedeac495271d0f";
export const USDT_ADDRESS = "0xdac17f958d2ee523a2206206994597c13d831ec7";

// Uniswap Pool Addresses
export const uCR_uAD_ADDRESS = "0x429630355C3Ab8E7AceCD99B78BE2D37Bb939E27";
export const uCR_USDC_ADDRESS = "0x895BEbB725be4b1B9168508b84a811c7710EfB3C";
export const uCR_DAI_ADDRESS = "0x587B192f4c2c4C9115Ea1E0Fe4129d5188eC3728";
export const uCR_USDT_ADDRESS = "0x9d498aB38Aa889AE0f4A865d30da2116ee9716bC";

export const safeParseEther = (val: string) => {
  try {
    return ethers.utils.parseEther(val);
  } catch (e) {
    return null;
  }
};
