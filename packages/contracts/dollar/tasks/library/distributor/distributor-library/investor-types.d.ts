export interface Investor {
  name: string; // name of the recipient
  address: string; // Address of the recipient
  percent: number; // percentage of the emissions that the recipient is receiving
}
export interface InvestorWithTransfers extends Investor {
  transferred: number;
  transactions: string[];
}
// export interface VerifiedInvestor extends Investor {
//   received: number;
// }
