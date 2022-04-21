const Address = (props: { address: string; title: string }): JSX.Element => (
  <a
    className="mb-4 -mt-2 block break-words text-center text-xs !text-white/30"
    target="_blank"
    title={props.title}
    href={`https://etherscan.io/address/${props.address}`}
  >
    {props.address}
  </a>
);

export default Address;
