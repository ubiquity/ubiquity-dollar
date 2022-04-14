export const Container = (props: React.PropsWithChildren<{ className?: string }>): JSX.Element => (
  <div
    className={`
      relative
      text-white/50 tracking-wide
      p-8 mb-8 mx-auto max-w-screen-md rounded-lg bg-paper border border-solid border-accent/60
      ${props.className || ""}`}
  >
    {props.children}
  </div>
);

export const Title = (props: { text: string }): JSX.Element => <div className="uppercase tracking-widest text-white/75 text-lg mb-4">{props.text}</div>;

export const SubTitle = (props: { text: string }): JSX.Element => <div className="text-center uppercase my-4 tracking-widest text-xs">{props.text}</div>;

export const Address = (props: { address: string; title: string }): JSX.Element => (
  <a
    className="block text-center break-words text-xs mb-4 -mt-2 !text-white/30"
    target="_blank"
    title={props.title}
    href={`https://etherscan.io/address/${props.address}`}
  >
    {props.address}
  </a>
);

export const Balance = (props: { balance: number; unit: string; title: string }): JSX.Element => (
  <div className="flex">
    <div className="text-white/75 w-1/2">{props.title}</div>
    <div>
      <span className="text-white/75 mr-2">{props.unit}</span>
      {props.balance}
    </div>
  </div>
);

export const PriceExchange = (props: { from: string; to: string; value: number }): JSX.Element => (
  <div className="flex">
    <span className="w-1/2 text-right">
      1 <span className="text-white text-opacity-75">{props.from}</span>
    </span>
    <span className="w-8 -mt-1 text-center">⇄</span>
    <span className="w-1/2 flex-grow text-left">
      {props.value.toString()} <span className="text-white text-opacity-75">{props.to}</span>
    </span>
  </div>
);

export const Loading = (props: { text: string }): JSX.Element => (
  <div className="h-20 flex items-center justify-center text-lg text-white text-opacity-25">
    <span className="mr-4">{props.text}</span>
    <span className="scale-150">{Spinner}</span>
  </div>
);

export const Spinner = (
  <div className="lds-ring relative top-[2px]">
    <div></div>
    <div></div>
    <div></div>
    <div></div>
  </div>
);
