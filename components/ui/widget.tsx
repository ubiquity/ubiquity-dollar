import { Icon } from "./icons";
import Tippy from "@tippyjs/react";
import React from "react";

export const Container = (props: React.PropsWithChildren<{ className?: string }>): JSX.Element => (
  <div
    className={`
      relative
      mx-auto mb-8
      max-w-screen-md rounded-lg border border-solid border-accent/60 bg-paper p-8 tracking-wide text-white/75
      ${props.className || ""}`}
  >
    {props.children}
  </div>
);

export const Title = (props: { text: string }): JSX.Element => <div className="mb-4 text-lg uppercase tracking-widest text-white/75">{props.text}</div>;

export const SubTitle = (props: { text: string }): JSX.Element => (
  <div className="mb-8 -mt-4 text-center text-xs uppercase tracking-widest text-white/50">{props.text}</div>
);

export const Address = (props: { address: string; title: string }): JSX.Element => (
  <a
    className="mb-4 -mt-2 block break-words text-center text-xs !text-white/30"
    target="_blank"
    title={props.title}
    href={`https://etherscan.io/address/${props.address}`}
  >
    {props.address}
  </a>
);

export const Balance = (props: { balance: number; unit: string; title: string }): JSX.Element => (
  <div className="flex">
    <div className="w-1/2 text-white/75">{props.title}</div>
    <div>
      <span className="mr-2 text-white/75">{props.unit}</span>
      {props.balance}
    </div>
  </div>
);

export const PriceExchange = (props: { from: string; to: string; value: number }): JSX.Element => (
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

export const Loading = (props: { text: string }): JSX.Element => (
  <div className="flex h-20 items-center justify-center text-lg text-white text-opacity-25">
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

export const WalletNotConnected = (
  <div className="flex items-center rounded-xl bg-white/10 p-8 text-lg text-white/50">
    <div className="mr-8 w-20">
      <Icon icon="wallet" />
    </div>
    Connect wallet to continue
  </div>
);

export const Tooltip = ({ children, title }: { children: React.ReactElement; title: string }) => (
  <Tippy
    content={
      <div className="rounded-md border border-solid border-white/10 bg-paper px-4 py-2 text-sm" style={{ backdropFilter: "blur(8px)" }}>
        <p className="text-center text-white/50">{title}</p>
      </div>
    }
    placement="top"
    duration={0}
  >
    {children}
  </Tippy>
);
