const PriceExchange = (props: { from: string; to: string; value: number }): JSX.Element => (
  <div className="flex">
    <span className="w-1/2 text-right">
      1 <span className="text-white text-opacity-75">{props.from}</span>
    </span>
    <span className="-mt-1 w-8 text-center">⇄</span>
    <span className="w-1/2 flex-grow text-left">
      {props.value.toString()} <span className="text-white text-opacity-75">{props.to}</span>
    </span>
  </div>
);

export default PriceExchange;
