import { BigNumber, ethers } from "ethers";
import { createContext, Dispatch, SetStateAction, useContext, useState, useEffect } from "react";

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

const ConnectedContext = createContext<ConnectedContext>({} as ConnectedContext);

interface Props {
  children: React.ReactNode;
}

export const ConnectedNetwork = (props: Props): JSX.Element => {
  const [provider, setProvider] = useState<ethers.providers.Web3Provider | null>(null);
  const [manager, setManager] = useState<UbiquityAlgorithmicDollarManager | null>(null);
  const [account, setAccount] = useState<EthAccount | null>(null);
  const [balances, setBalances] = useState<Balances | null>(null);
  const [twapPrice, setTwapPrice] = useState<BigNumber | null>(null);
  const [contracts, setContracts] = useState<Contracts | null>(null);

  const value: ConnectedContext = {
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

  useEffect(() => {
    (async function () {
      console.log("CONNECTING CONTRACTS!");
      const { provider, contracts } = await connectedContracts();
      (window as any).contracts = contracts;
      (window as any).account = await provider.getSigner().getAddress();
      (window as any).provider = provider;

      setProvider(provider);
      setContracts(contracts);
      setManager(contracts.manager);
    })();
  }, []);

  return <ConnectedContext.Provider value={value}>{props.children}</ConnectedContext.Provider>;
};

export const useConnectedContext = (): ConnectedContext => useContext(ConnectedContext);

// export function useInitializeContextContracts(): void {
//   const { provider, account, contracts, setProvider, setContracts, setManager } = useConnectedContext();

//   useEffect(() => {
//     (async function () {
//       if (!provider) {
//         console.log("CONNECTING CONTRACTS!");
//         const { provider, contracts } = await connectedContracts();
//         (window as any).contracts = contracts;
//         (window as any).account = await provider.getSigner().getAddress();

//         setProvider(provider);
//         setContracts(contracts);
//         setManager(contracts.manager);
//       }
//     })();
//   }, []);

//   // useEffect(() => {
//   //   if (account && contracts) {
//   //     for (let k in contracts) {

//   //     }
//   //     contracts.manager.connect(account.address);
//   //   }
//   // }, [account, contracts])
// }

type ContractsCallback = ({ contracts, provider }: { contracts: Contracts; provider: ethers.providers.Web3Provider }) => Promise<void>;
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

type ConctractsWithAccountCallback = ({
  contracts,
  provider,
  account,
}: {
  contracts: Contracts;
  provider: ethers.providers.Web3Provider;
  account: EthAccount;
}) => Promise<void>;
export function useConnectedContractsWithAccount(callback: ConctractsWithAccountCallback): void {
  const { provider, account, contracts } = useConnectedContext();

  useEffect(() => {
    if (provider && account && contracts) {
      (async function () {
        callback({ contracts, provider, account });
      })();
    }
  }, [provider, account, contracts]);
}
