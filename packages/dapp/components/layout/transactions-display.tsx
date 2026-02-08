import useTransactionLogger, { Transaction } from "../lib/hooks/use-transaction-logger";
import Button from "../ui/button";
import Spinner from "../ui/spinner";

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
                  <span>This is a common error caused by mismatched transaction number after the development server is restarted,</span>
                  <a href="https://medium.com/@thelasthash/solved-nonce-too-high-error-with-metamask-and-hardhat-adc66f092cd">
                    <span>can be easily resolved by resetting the MetaMask account</span>
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
      <span>{props.transaction.title}</span>
      <span>{Spinner}</span>
    </div>
  );
};

const TransactionsDisplay = () => {
  const [transactions, , , dismissTransaction] = useTransactionLogger();

  return (
    <div id="TransactionsDisplay">
      {Object.entries(transactions).map(([key, transaction]) => (
        <Transacting key={key} transaction={transaction as Transaction} onDismiss={() => dismissTransaction(key)} />
      ))}
    </div>
  );
};

export default TransactionsDisplay;
