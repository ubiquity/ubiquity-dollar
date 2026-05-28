import { BalancesContextProvider } from "./hooks/use-balances";
import { TransactionsContextProvider } from "./hooks/use-transaction-logger";
import { UseWeb3Provider } from "./hooks/use-web-3";

import { combineComponents } from "./combine-components";

// const providers = [UseWeb3Provider, ManagedContractsContextProvider, TransactionsContextProvider, BalancesContextProvider];
// @note Fix: (Error: missing revert data in call exception since Diamond isn't deployed yet)
const providers = [UseWeb3Provider, TransactionsContextProvider, BalancesContextProvider];

const AppContextProvider = combineComponents(...providers);

export default AppContextProvider;
