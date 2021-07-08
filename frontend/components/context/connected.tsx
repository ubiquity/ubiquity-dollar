import { BigNumber, ethers } from "ethers";
import {
  createContext,
  Dispatch,
  SetStateAction,
  useContext,
  useState,
} from "react";

import { UbiquityAlgorithmicDollarManager } from "../../src/types/UbiquityAlgorithmicDollarManager";
import { EthAccount } from "../../utils/types";
import { Contracts } from "../../src/contracts";

export interface Balances {
  uad: BigNumber;
  crv: BigNumber;
  uad3crv: BigNumber;
  uar: BigNumber;
  ubq: BigNumber;
  bondingShares: BigNumber;
  debtCoupon: BigNumber;
}

export interface IConnectedContext {
  manager: UbiquityAlgorithmicDollarManager | null;
  provider: ethers.providers.Web3Provider | null;
  account: EthAccount | null;
  setAccount: Dispatch<SetStateAction<EthAccount | null>>;
  setProvider: Dispatch<SetStateAction<ethers.providers.Web3Provider | null>>;
  setManager: Dispatch<SetStateAction<UbiquityAlgorithmicDollarManager | null>>;
  balances: Balances | null;
  setBalances: Dispatch<SetStateAction<Balances | null>>;
  twapPrice: BigNumber | null;
  setTwapPrice: Dispatch<SetStateAction<BigNumber | null>>;
  contracts: Contracts | null;
  setContracts: Dispatch<SetStateAction<Contracts | null>>;
}

// We can cast it safely here because we are actually setting the value on ConnectedNetwork
const ConnectedContext = createContext<IConnectedContext>(
  {} as IConnectedContext
);

interface Props {
  children: React.ReactNode;
  // window: Window & typeof globalThis;
}

export const ConnectedNetwork = (props: Props): JSX.Element => {
  const [
    provider,
    setProvider,
  ] = useState<ethers.providers.Web3Provider | null>(null);
  const [
    manager,
    setManager,
  ] = useState<UbiquityAlgorithmicDollarManager | null>(null);
  const [account, setAccount] = useState<EthAccount | null>(null);
  const [balances, setBalances] = useState<Balances | null>(null);
  const [twapPrice, setTwapPrice] = useState<BigNumber | null>(null);
  const [contracts, setContracts] = useState<Contracts | null>(null);

  const value: IConnectedContext = {
    provider,
    setProvider,
    manager,
    setManager,
    account,
    setAccount,
    balances,
    setBalances,
    twapPrice,
    setTwapPrice,
    contracts,
    setContracts,
  };

  return (
    <ConnectedContext.Provider value={value}>
      {props.children}
    </ConnectedContext.Provider>
  );
};

export const useConnectedContext = (): IConnectedContext =>
  useContext(ConnectedContext);
