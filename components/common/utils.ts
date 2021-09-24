import { ethers, ContractTransaction } from "ethers";
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
