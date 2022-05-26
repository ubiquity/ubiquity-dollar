import { UseWeb3Provider } from "./hooks/useWeb3";
import { ManagedContractsContextProvider } from "./hooks/contracts/useManagerManaged";
import { TransactionsContextProvider } from "./hooks/useTransactionLogger";
import { BalancesContextProvider } from "./hooks/useBalances";

import { combineComponents } from "./combineComponents";

const providers = [UseWeb3Provider, ManagedContractsContextProvider, TransactionsContextProvider, BalancesContextProvider];

const AppContextProvider = combineComponents(...providers);

export default AppContextProvider;
