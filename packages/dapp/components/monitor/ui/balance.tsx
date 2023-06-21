const Balance = (props: { balance: number; unit?: string; title: string }): JSX.Element => (
  <div>
    <span>{props.title}</span> <span>{props.balance}</span>
  </div>
);

export default Balance;
