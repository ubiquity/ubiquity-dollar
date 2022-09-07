const Balance = (props: { balance: number; unit: string; title: string }): JSX.Element => (
  <div>
    <div>{props.title}</div>
    <div>
      <span>{props.unit}</span>
      {props.balance}
    </div>
  </div>
);

export default Balance;
