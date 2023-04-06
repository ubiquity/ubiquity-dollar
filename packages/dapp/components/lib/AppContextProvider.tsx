import { ManagedContractsContextProvider } from "./hooks/contracts/useManagerManaged";
import { BalancesContextProvider } from "./hooks/useBalances";
import { TransactionsContextProvider } from "./hooks/useTransactionLogger";
import { UseWeb3Provider } from "./hooks/useWeb3";

import { combineComponents } from "./combineComponents";

// const providers = [UseWeb3Provider, ManagedContractsContextProvider, TransactionsContextProvider, BalancesContextProvider];
// @note Fix: (Error: missing revert data in call exception since Diamond isn't deployed yet)
const providers = [UseWeb3Provider, TransactionsContextProvider, BalancesContextProvider];

const AppContextProvider = combineComponents(...providers);

export default AppContextProvider;
