import { LogAndEvents } from "../read-contract-transaction-history";
export default function transferFilter(tx: LogAndEvents): boolean {
  if (tx.events.topic === "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef") return true;
  else if (tx.events.signature === "Transfer(address,address,uint256)") return true;
  else if (tx.events.name === "Transfer") return true;
  return false;
}
