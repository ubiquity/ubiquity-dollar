import { ethers } from "ethers";
import {
  createContext,
  Dispatch,
  SetStateAction,
  useContext,
  useState,
} from "react";
import {
  Bonding,
  BondingShare,
  MasterChef,
  UbiquityAlgorithmicDollar,
  UbiquityAlgorithmicDollar__factory,
  UbiquityAutoRedeem,
  UbiquityGovernance,
} from "../../src/types";
import { IMetaPool } from "../../src/types/IMetaPool";
import { UbiquityAlgorithmicDollarManager } from "../../src/types/UbiquityAlgorithmicDollarManager";
import { Account } from "../utils/types";

export interface IConnectedContext {
  manager: UbiquityAlgorithmicDollarManager | undefined;
  provider: ethers.providers.Web3Provider | undefined;
  account: Account | undefined;
  metapool: IMetaPool | undefined;
  bonding: Bonding | undefined;
  bondingShare: BondingShare | undefined;
  masterChef: MasterChef | undefined;
  uAR: UbiquityAutoRedeem | undefined;
  uGov: UbiquityGovernance | undefined;
  uAD: UbiquityAlgorithmicDollar | undefined;

  setAccount: Dispatch<SetStateAction<Account | undefined>>;
  setProvider: Dispatch<
    SetStateAction<ethers.providers.Web3Provider | undefined>
  >;
  setManager: Dispatch<
    SetStateAction<UbiquityAlgorithmicDollarManager | undefined>
  >;
  setMetapool: Dispatch<SetStateAction<IMetaPool | undefined>>;
  setBonding: Dispatch<SetStateAction<Bonding | undefined>>;
  setBondingShare: Dispatch<SetStateAction<BondingShare | undefined>>;
  setMasterChef: Dispatch<SetStateAction<MasterChef | undefined>>;
  setUAR: Dispatch<SetStateAction<UbiquityAutoRedeem | undefined>>;
  setUGOV: Dispatch<SetStateAction<UbiquityGovernance | undefined>>;
  setUAD: Dispatch<SetStateAction<UbiquityAlgorithmicDollar | undefined>>;
}
export const CONNECTED_CONTEXT_DEFAULT_VALUE = {
  manager: undefined,
  provider: undefined,
  account: undefined,
  metapool: undefined,
  bonding: undefined,
  bondingShare: undefined,
  setProvider: () => {},
  setAccount: () => {},
  setManager: () => {},
  setMetapool: () => {},
  setBonding: () => {},
  setBondingShare: () => {},
  masterChef: undefined,
  setMasterChef: () => {},
  uAR: undefined,
  setUAR: () => {},
  uGov: undefined,
  setUGOV: () => {},
  uAD: undefined,
  setUAD: () => {},
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
  const [account, setAccount] = useState<Account>();
  const [metapool, setMetapool] = useState<IMetaPool>();
  const [bonding, setBonding] = useState<Bonding>();
  const [bondingShare, setBondingShare] = useState<BondingShare>();
  const [masterChef, setMasterChef] = useState<MasterChef>();
  const [uAR, setUAR] = useState<UbiquityAutoRedeem>();
  const [uGov, setUGOV] = useState<UbiquityGovernance>();
  const [uAD, setUAD] = useState<UbiquityAlgorithmicDollar>();

  const value = {
    provider,
    manager,
    setManager,
    account,
    setAccount,
    setProvider,
    metapool,
    setMetapool,
    bonding,
    setBonding,
    bondingShare,
    setBondingShare,
    masterChef,
    setMasterChef,
    uAR,
    setUAR,
    uGov,
    setUGOV,
    uAD,
    setUAD,
  };

  return (
    <ConnectedContext.Provider value={value}>
      {props.children}
    </ConnectedContext.Provider>
  );
};

export const useConnectedContext = (): IConnectedContext =>
  useContext(ConnectedContext);
