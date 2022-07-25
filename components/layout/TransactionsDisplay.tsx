import { Transaction, useTransactionLogger } from "@/lib/hooks";
import { Button, Spinner } from "../ui";

export const Transacting = (props: { transaction: Transaction; onDismiss: () => void }): JSX.Element | null => {
  if (props.transaction.status === "failure" && !props.transaction.dismissed) {
    return (
      <div className="mt-1 w-96">
        <div className="rounded-t-lg border border-solid border-red-400 bg-red-400/10 px-4 py-1  text-red-400">{props.transaction.title} failed</div>
        <div className="rounded-b-lg border border-t-0 border-solid border-gray-400 bg-gray-400/10 p-4 text-white/75 opacity-75">
          {props.transaction.error ? (
            <>
              <pre className="whitespace-normal">{props.transaction.error}</pre>
              {/Nonce too high/.test(props.transaction.error) ? (
                <div className="mt-4">
                  This is a common error caused by mismatched transaction number after the development server is restarted,{" "}
                  <a
                    className="pointer-events-auto underline"
                    href="https://medium.com/@thelasthash/solved-nonce-too-high-error-with-metamask-and-hardhat-adc66f092cd"
                  >
                    can be easily resolved by resetting the Metamask account
                  </a>
                </div>
              ) : null}
            </>
          ) : null}
          <div className="pointer-events-auto text-right">
            <Button onClick={props.onDismiss}>Dismiss</Button>
          </div>
        </div>
      </div>
    );
  }

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
  const [transactions, , , dismissTransaction] = useTransactionLogger();

  return (
    <div className="pointer-events-none fixed top-0 right-0 z-50 mr-8 mt-16">
      {Object.entries(transactions).map(([key, transaction]) => (
        <Transacting key={key} transaction={transaction} onDismiss={() => dismissTransaction(key)} />
      ))}
    </div>
  );
};

export default TransactionsDisplay;
