import { WalletAddressContextProvider } from "./hooks/useWalletAddress";
import { ManagedContractsContextProvider } from "./hooks/contracts/useManagerManaged";
import { TransactionsContextProvider } from "./hooks/useTransactionLogger";
import { BalancesContextProvider } from "./hooks/useBalances";

import { combineComponents } from "./combineComponents";

const providers = [WalletAddressContextProvider, ManagedContractsContextProvider, TransactionsContextProvider, BalancesContextProvider];

const AppContextProvider = combineComponents(...providers);

export default AppContextProvider;
