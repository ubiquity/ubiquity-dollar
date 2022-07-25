import { ContactWithTransfers } from "../calculate-owed-emissions";
import { getTranches } from "./getTranches";

export async function sumTotalSentToContacts() {
  const transferAmountsToContacts = addressBook.map(addressMapper);
  // console.log(transferAmountsToContacts);
  return transferAmountsToContacts;

  async function addressMapper(contact: ContactWithTransfers) {
    // const contact = _contact as ; // type casting
    const tranches = await getTranches();
    tranches.forEach((tranche) => {
      if (!contact.transferred) {
        contact.transferred = 0;
      }

      if (!contact.transactions) {
        contact.transactions = [];
      }

      if (tranche.name === contact.name) {
        contact.transferred += tranche.amount;
        contact.transactions.push(tranche.hash);
      }
    });
    return contact;
  }
}
