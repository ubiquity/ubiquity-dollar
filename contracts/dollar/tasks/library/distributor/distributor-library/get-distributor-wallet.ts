import { Wallet } from "ethers";

export function getDistributorWallet(): Wallet {
  if (process.env.UBQ_DISTRIBUTOR) {
    //  = "0x445115D7c301E6cC3B5A21cE86ffCd8Df6EaAad9";
    return new Wallet(process.env.UBQ_DISTRIBUTOR);
  } else {
    throw new Error("private key required for process.env.UBQ_DISTRIBUTOR to distribute tokens");
  }
}
