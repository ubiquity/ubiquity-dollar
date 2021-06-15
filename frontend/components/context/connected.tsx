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

export interface Balances {
  uad: BigNumber;
  crv: BigNumber;
  uad3crv: BigNumber;
  uar: BigNumber;
  ubq: BigNumber;
  bondingShares: BigNumber;
  debtCoupon: BigNumber;
  // window: Window & typeof globalThis;
}

export interface IConnectedContext {
  manager: UbiquityAlgorithmicDollarManager | undefined;
  provider: ethers.providers.Web3Provider | undefined;
  account: EthAccount | undefined;
  setAccount: Dispatch<SetStateAction<EthAccount | undefined>>;
  setProvider: Dispatch<
    SetStateAction<ethers.providers.Web3Provider | undefined>
  >;
  setManager: Dispatch<
    SetStateAction<UbiquityAlgorithmicDollarManager | undefined>
  >;
  balances: Balances | undefined;
  setBalances: Dispatch<SetStateAction<Balances | undefined>>;
  twapPrice: BigNumber | undefined;
  setTwapPrice: Dispatch<SetStateAction<BigNumber | undefined>>;
}
export const CONNECTED_CONTEXT_DEFAULT_VALUE = {
  manager: undefined,
  setManager: () => {},
  provider: undefined,
  account: undefined,
  setProvider: () => {},
  setAccount: () => {},
  balances: {
    uad: BigNumber.from(0),
    crv: BigNumber.from(0),
    uad3crv: BigNumber.from(0),
    uar: BigNumber.from(0),
    ubq: BigNumber.from(0),
    bondingShares: BigNumber.from(0),
    debtCoupon: BigNumber.from(0),
  },
  setBalances: () => {},
  twapPrice: undefined,
  setTwapPrice: () => {},
};
const ConnectedContext = createContext<IConnectedContext>(
  CONNECTED_CONTEXT_DEFAULT_VALUE
);
interface Props {
  children: React.ReactNode;
  // window: Window & typeof globalThis;
}

export const ConnectedNetwork = (props: Props) => {
  const [provider, setProvider] = useState<ethers.providers.Web3Provider>();
  const [manager, setManager] = useState<UbiquityAlgorithmicDollarManager>();
  const [account, setAccount] = useState<EthAccount>();
  const [balances, setBalances] = useState<Balances>();
  const [twapPrice, setTwapPrice] = useState<BigNumber>();

  const value = {
    provider,
    manager,
    setManager,
    account,
    setAccount,
    setProvider,
    balances,
    setBalances,
    twapPrice,
    setTwapPrice,
  };

  return (
    <ConnectedContext.Provider value={value}>
      {props.children}
    </ConnectedContext.Provider>
  );
};

export const useConnectedContext = (): IConnectedContext =>
  useContext(ConnectedContext);
