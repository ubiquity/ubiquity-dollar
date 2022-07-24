export interface TaskArgs {
  investors: string; // path to json file containing a list of investors
  token: string; // address of the token
}

export interface Investor {
  name: string; // name of the recipient
  address: string; // Address of the recipient
  percent: number; // percentage of the emissions that the recipient is receiving
}

export interface VerifiedInvestor extends Investor {
  received: number;
}
