import { LogDescription } from "@ethersproject/abi";
import { Log } from "@ethersproject/providers";
import { Investor } from "../investor-types";

export function transfersToInvestorsFilterWrapper(investors: Investor[]) {
  return function transfersToInvestorsFilter(txEmits: { events: LogDescription; log: Log }) {
    const to = txEmits.events.args[1] as string;
    const _amount = txEmits.events.args[2]._hex as string;
    const amount = parseInt(_amount) / 1e18;

    // very fast way to see if the recipient is in the address book
    let x = investors.length;
    while (x--) {
      if (investors[x].address === to) {
        return {
          name: investors[x].name,
          hash: txEmits.log.transactionHash,
          from: txEmits.events.args[0] as string,
          to: txEmits.events.args[1] as string,
          amount,
        };
      }
    }
  };
}

export interface Tranche {
  name: string;
  hash: string;
  from: string;
  to: string;
  amount: number;
}
