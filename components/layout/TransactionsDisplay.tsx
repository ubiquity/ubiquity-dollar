import { useTransactionLogger, Transaction } from "@/lib/hooks";
import { Spinner } from "../ui";

export const Transacting = (props: { transaction: Transaction }): JSX.Element | null => {
  if (props.transaction.endTime) {
    return null;
  }

  return (
    <div className="mt-1 rounded-full border border-solid border-accent bg-accent bg-opacity-10 py-1 px-4 text-accent">
      {props.transaction.title} {Spinner}
    </div>
  );
};

const TransactionsDisplay = () => {
  const [transactions] = useTransactionLogger();

  return (
    <div className="pointer-events-none fixed top-0 right-0 mr-8 mt-16">
      {Object.values(transactions).map((transaction) => (
        <Transacting key={transaction.startTime} transaction={transaction} />
      ))}
    </div>
  );
};

export default TransactionsDisplay;
