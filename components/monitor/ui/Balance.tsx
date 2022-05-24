const Balance = (props: { balance: number; unit: string; title: string }): JSX.Element => (
  <div className="flex">
    <div className="w-1/2 text-white/75">{props.title}</div>
    <div>
      <span className="mr-2 text-white/75">{props.unit}</span>
      {props.balance}
    </div>
  </div>
);

export default Balance;
