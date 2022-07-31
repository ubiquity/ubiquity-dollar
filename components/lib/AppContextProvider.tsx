import { ManagedContractsContextProvider } from "./hooks/contracts/useManagerManaged";
import { BalancesContextProvider } from "./hooks/useBalances";
import { TransactionsContextProvider } from "./hooks/useTransactionLogger";
import { UseWeb3Provider } from "./hooks/useWeb3";

import { combineComponents } from "./combineComponents";

const providers = [UseWeb3Provider, ManagedContractsContextProvider, TransactionsContextProvider, BalancesContextProvider];

const _AppContextProvider = combineComponents(...providers);

export default _AppContextProvider;
