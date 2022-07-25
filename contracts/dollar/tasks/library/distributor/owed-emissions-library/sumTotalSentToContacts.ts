import { Investor, InvestorWithTransfers } from "../distributor-library/investor-types";
import { Tranche } from "../distributor-library/log-filters/transfers-to-investors";

export async function sumTotalSentToContacts(Investors: Investor[], tranches: Tranche[]): Promise<InvestorWithTransfers[]> {
  let transferAmounts = [] as InvestorWithTransfers[];
  for (const investor of Investors) {
    transferAmounts.push(getTransferAmounts(investor, tranches));
  }
  return transferAmounts;
}

function getTransferAmounts(investor: Investor, tranches: Tranche[]) {
  let investorWithTransfers = Object.assign({}, investor) as InvestorWithTransfers;
  tranches.forEach((tranche: Tranche) => {
    if (!investorWithTransfers.transferred) {
      investorWithTransfers.transferred = 0;
    }

    if (!investorWithTransfers.transactions) {
      investorWithTransfers.transactions = [];
    }

    if (tranche.name === investorWithTransfers.name) {
      investorWithTransfers.transferred += tranche.amount;
      investorWithTransfers.transactions.push(tranche.hash);
    }
  });

  return investorWithTransfers;
}
