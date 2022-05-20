export interface EthAccount {
  balance: number;
  address: string;
}

export interface Transaction {
  id: string;
  active: boolean;
  title?: string;
}
