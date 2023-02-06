const PriceExchange = (props: { from: string; to: string; value: number }): JSX.Element => (
  <div>
    <span>
      1 <span>{props.from}</span>
    </span>
    <span>⇄</span>
    <span>
      {props.value.toString()} <span>{props.to}</span>
    </span>
  </div>
);

export default PriceExchange;
