import { useContext, useState, createContext } from "react";

export type Transaction = {
  title: string;
  startTime: number;
  endTime: null | number;
};

type Transactions = { [key: string]: Transaction };
type DoTransactionType = (title: string, wrappedFun: () => Promise<void>) => Promise<void>;

type TransactionLogger = [Transactions, DoTransactionType, boolean];

export const TransactionsContext = createContext<TransactionLogger>([{}, async () => {}, false]);

export const TransactionsContextProvider: React.FC = ({ children }) => {
  const [transactions, setTransactions] = useState<Transactions>({});

  const doTransaction = async (title: string, wrappedFun: () => Promise<void>) => {
    const startTime = +new Date();
    let transaction: Transaction = { title, startTime, endTime: null };
    setTransactions({ ...transactions, [startTime]: transaction });
    await wrappedFun();
    transaction = { ...transaction, endTime: +new Date() };
    setTransactions({ ...transactions, [startTime]: transaction });
  };

  const activeTransactions = Object.values(transactions).filter((t) => !t.endTime);
  const doingTransactions = activeTransactions.length > 0;

  return <TransactionsContext.Provider value={[transactions, doTransaction, doingTransactions]}>{children}</TransactionsContext.Provider>;
};

const useTransactionLogger = () => useContext(TransactionsContext);

export default useTransactionLogger;

// // ToDo: Store on localStorage so user can check transaction history
