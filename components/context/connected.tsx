import { BigNumber, ethers } from "ethers";
import { createContext, Dispatch, SetStateAction, useContext, useState, useEffect, useCallback } from "react";

import { UbiquityAlgorithmicDollarManager } from "../../contracts/artifacts/types/UbiquityAlgorithmicDollarManager";
import { EthAccount } from "../common/types";
import { connectedContracts, Contracts } from "../../contracts";

export interface Balances {
  uad: BigNumber;
  crv: BigNumber;
  uad3crv: BigNumber;
  uar: BigNumber;
  ubq: BigNumber;
  bondingShares: BigNumber;
  bondingSharesLP: BigNumber;
  debtCoupon: BigNumber;
}

export interface ConnectedContext {
  manager: UbiquityAlgorithmicDollarManager | null;
  setManager: Dispatch<SetStateAction<UbiquityAlgorithmicDollarManager | null>>;
  provider: ethers.providers.Web3Provider | null;
  setProvider: Dispatch<SetStateAction<ethers.providers.Web3Provider | null>>;
  account: EthAccount | null;
  setAccount: Dispatch<SetStateAction<EthAccount | null>>;
  signer: ethers.providers.JsonRpcSigner | null;
  setSigner: Dispatch<SetStateAction<ethers.providers.JsonRpcSigner | null>>;
  balances: Balances | null;
  setBalances: Dispatch<SetStateAction<Balances | null>>;
  twapPrice: BigNumber | null;
  setTwapPrice: Dispatch<SetStateAction<BigNumber | null>>;
  contracts: Contracts | null;
  setContracts: Dispatch<SetStateAction<Contracts | null>>;
}

const ConnectedContext = createContext<ConnectedContext>({} as ConnectedContext);

interface Props {
  children: React.ReactNode;
}

export const ConnectedNetwork = (props: Props): JSX.Element => {
  const [provider, setProvider] = useState<ethers.providers.Web3Provider | null>(null);
  const [signer, setSigner] = useState<ethers.providers.JsonRpcSigner | null>(null);
  const [manager, setManager] = useState<UbiquityAlgorithmicDollarManager | null>(null);
  const [account, setAccount] = useState<EthAccount | null>(null);
  const [balances, setBalances] = useState<Balances | null>(null);
  const [twapPrice, setTwapPrice] = useState<BigNumber | null>(null);
  const [contracts, setContracts] = useState<Contracts | null>(null);

  const value: ConnectedContext = {
    provider,
    setProvider,
    signer,
    setSigner,
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

  useEffect(() => {
    (async function () {
      console.time("Connecting contracts");
      const { provider, contracts } = await connectedContracts();
      const signer = await provider.getSigner();
      console.timeEnd("Connecting contracts");
      (window as any).contracts = contracts;
      (window as any).signer = signer;
      (window as any).account = await provider.getSigner().getAddress();
      (window as any).provider = provider;

      setSigner(signer);
      setProvider(provider);
      setContracts(contracts);
      setManager(contracts.manager);
    })();
  }, []);

  return <ConnectedContext.Provider value={value}>{props.children}</ConnectedContext.Provider>;
};

export const useConnectedContext = (): ConnectedContext => useContext(ConnectedContext);

export type UnconnectedContractsKit = {
  contracts: Contracts;
  provider: ethers.providers.Web3Provider;
};

type ContractsCallback = ({ contracts, provider }: UnconnectedContractsKit) => Promise<void>;
export function useConnectedContracts(callback: ContractsCallback): void {
  const { provider, account, contracts } = useConnectedContext();

  useEffect(() => {
    if (provider && account && contracts) {
      (async function () {
        callback({ contracts, provider });
      })();
    }
  }, [provider, contracts]);
}

export type ConnectedContractsKit = {
  contracts: Contracts;
  provider: ethers.providers.Web3Provider;
  account: EthAccount;
  signer: ethers.providers.JsonRpcSigner;
};

type ContractsWithAccountCallback = (data: ConnectedContractsKit) => Promise<void>;
export function useConnectedContractsWithAccount(callback: ContractsWithAccountCallback): void {
  const { provider, account, signer, contracts } = useConnectedContext();

  useEffect(() => {
    if (provider && account && signer && contracts) {
      (async function () {
        callback({ contracts, provider, account, signer });
      })();
    }
  }, [provider, account, contracts]);
}

export function useContractsCallback<T>(cb: (data: ConnectedContractsKit, payload: T) => void): (payload: T) => void {
  const { provider, account, contracts, signer } = useConnectedContext();

  return useCallback(
    (payload: T) => {
      if (provider && account && signer && contracts) {
        cb({ contracts, provider, account, signer }, payload);
      }
    },
    [provider, contracts, account]
  );
}
