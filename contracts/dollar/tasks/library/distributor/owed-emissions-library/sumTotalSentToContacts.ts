import { InvestorWithTransfers } from "../distributor-library/investor-types";
import { Tranche } from "../distributor-library/log-filters/transfers-to-investors";

export async function sumTotalSentToContacts(investorsWithTransfers: InvestorWithTransfers[], tranches: Tranche[]) {
  let transferAmounts = [] as InvestorWithTransfers[];
  for (const contact of investorsWithTransfers) {
    transferAmounts.push(getTransferAmounts(contact, tranches));
  }
  return transferAmounts;
}

function getTransferAmounts(investor: InvestorWithTransfers, tranches: Tranche[]) {
  tranches.forEach((tranche: Tranche) => {
    if (!investor.transferred) {
      investor.transferred = 0;
    }

    if (!investor.transactions) {
      investor.transactions = [];
    }

    if (tranche.name === investor.name) {
      investor.transferred += tranche.amount;
      investor.transactions.push(tranche.hash);
    }
  });
  return investor;
}
