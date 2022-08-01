import { Transaction, useTransactionLogger } from "@/lib/hooks";
import { Button, Spinner } from "../ui";

export const Transacting = (props: { transaction: Transaction; onDismiss: () => void }): JSX.Element | null => {
  if (props.transaction.status === "failure" && !props.transaction.dismissed) {
    return (
      <div>
        <div>{props.transaction.title} failed</div>
        <div>
          {props.transaction.error ? (
            <>
              <pre>{props.transaction.error}</pre>
              {/Nonce too high/.test(props.transaction.error) ? (
                <div>
                  This is a common error caused by mismatched transaction number after the development server is restarted,{" "}
                  <a href="https://medium.com/@thelasthash/solved-nonce-too-high-error-with-metamask-and-hardhat-adc66f092cd">
                    can be easily resolved by resetting the Metamask account
                  </a>
                </div>
              ) : null}
            </>
          ) : null}
          <div>
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
    <div>
      {props.transaction.title} {Spinner}
    </div>
  );
};

const TransactionsDisplay = () => {
  const [transactions, , , dismissTransaction] = useTransactionLogger();

  return (
    <div>
      {Object.entries(transactions).map(([key, transaction]) => (
        <Transacting key={key} transaction={transaction} onDismiss={() => dismissTransaction(key)} />
      ))}
    </div>
  );
};

export default TransactionsDisplay;
