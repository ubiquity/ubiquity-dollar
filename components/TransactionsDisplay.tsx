import { Transaction } from "./common/types";
import { useConnectedContext } from "./context/connected";
import { Spinner } from "./ui/widget";

export const Transacting = (props: { transaction: Transaction }): JSX.Element | null => {
  if (!props.transaction.active) {
    return null;
  }
  return (
    <div className="border-accent border bg-accent bg-opacity-10 border-solid mt-1 rounded-full py-1 px-4 text-accent">
      {props.transaction.title} {Spinner}
    </div>
  );
};

const TransactionsDisplay = () => {
  const { activeTransactions } = useConnectedContext();

  return (
    <div className="fixed top-0 right-0 mr-4 mt-4 pointer-events-none">
      {activeTransactions.map((transaction, index) => (
        <Transacting key={transaction.id + index} transaction={transaction} />
      ))}
    </div>
  );
};

export default TransactionsDisplay;
