import { LogAndEvents } from "../read-contract-transaction-history";
export default function mintFilter(tx: LogAndEvents): boolean {
  if (tx.events.topic === "0xb1233017d63154bc561d57c16f7b6a55e2e1acd7fcac94045a9f35fb31a850ca") return true;
  else if (tx.events.signature === "Minting(address,address,uint256)") return true;
  else if (tx.events.name === "Minting") return true;
  return false;
}
