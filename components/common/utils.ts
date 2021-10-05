import { ethers, ContractTransaction, BigNumber } from "ethers";
import { ERC1155Ubiquity } from "../../contracts/artifacts/types";
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
  try {
    const tx = await transaction;
    const txR = await tx.wait();
    logGas(txR);
    return true;
  } catch (e) {
    console.error("Transaction error", e);
  }
  return false;
}

export async function erc1155BalanceOf(addr: string, erc1155UbiquityCtr: ERC1155Ubiquity): Promise<BigNumber> {
  const treasuryIds = await erc1155UbiquityCtr.holderTokens(addr);

  const balanceOfs = treasuryIds.map((id) => {
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
