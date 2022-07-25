import { createContext, useContext, useState } from "react";

export type Transaction = {
  title: string;
  startTime: number;
  endTime: null | number;
  status: "pending" | "success" | "failure";
  dismissed: boolean;
  error: null | string;
};

type Transactions = { [key: string]: Transaction };
type DoTransactionType = (title: string, wrappedFun: () => Promise<void>) => Promise<boolean>;

type TransactionLogger = [Transactions, DoTransactionType, boolean, (transactionKey: string) => void];

export const TransactionsContext = createContext<TransactionLogger>([{}, async () => true, false, () => {}]);

export const TransactionsContextProvider: React.FC = ({ children }) => {
  const [transactions, setTransactions] = useState<Transactions>({});

  const doTransaction = async (title: string, wrappedFun: () => Promise<void>): Promise<boolean> => {
    const startTime = +new Date();
    let transaction: Transaction = { title, startTime, endTime: null, status: "pending", error: null, dismissed: false };
    setTransactions({ ...transactions, [startTime]: transaction });
    try {
      await wrappedFun();
      transaction.status = "success";
    } catch (e) {
      console.error("Transaction error", e);
      if (e) {
        const err = e as { message: string };
        const matchedRpcError = err.message.indexOf("outputs from RPC '");
        if (matchedRpcError !== -1) {
          const rpcErrorDetails = JSON.parse(err.message.slice(matchedRpcError + 18, -1));
          if (rpcErrorDetails?.value?.data?.message) {
            transaction.error = rpcErrorDetails.value.data.message;
          }
        }
      }
      transaction.status = "failure";
    }
    transaction = { ...transaction, endTime: +new Date() };
    setTransactions({ ...transactions, [startTime]: transaction });
    return transaction.status === "success";
  };

  const activeTransactions = Object.values(transactions).filter((t) => !t.endTime);
  const doingTransactions = activeTransactions.length > 0;

  const dismissTransaction = (startTime: string) => {
    console.log("Dismissing transaction", startTime);
    setTransactions({ ...transactions, [startTime]: { ...transactions[startTime], dismissed: true } });
  };

  return <TransactionsContext.Provider value={[transactions, doTransaction, doingTransactions, dismissTransaction]}>{children}</TransactionsContext.Provider>;
};

const useTransactionLogger = () => useContext(TransactionsContext);

export default useTransactionLogger;

// // ToDo: Store on localStorage so user can check transaction history
