import cx from "classnames";
import * as widget from "../ui/widget";
import { OwnedSticks, SticksAllowance, TokenMedia, TokenData } from "./lib/state";

// const mockAccount = typeof document !== "undefined" && document.location.search === "?test" ? "0xefC0e701A824943b469a694aC564Aa1efF7Ab7dd" : null;

type UbiquiStickParams = {
  isConnected: boolean;
  sticks: OwnedSticks | null;
  allowance: SticksAllowance | null;
  media: TokenMedia;
  onBuy: () => unknown;
};

const UbiquiStick = ({ isConnected, sticks, allowance, onBuy, media }: UbiquiStickParams) => {
  const sticksCount = sticks ? sticks.gold + sticks.black + sticks.invisible : null;

  const isLoaded = !!(sticks && allowance);

  const mintButtonEnabled = sticks && allowance && allowance.count > 0;
  const mintButtonText = !isConnected
    ? "Connect your wallet"
    : !isLoaded
    ? "Checking whitelist"
    : allowance.count === 0 && sticksCount !== 0
    ? "You reached your minting limit"
    : allowance.count === 0 && sticksCount === 0
    ? "You are not whitelisted to mint"
    : `Mint for ${allowance.price} ETH`;

  return (
    <widget.Container className="flex flex-col items-center">
      <widget.Title text="The Ubiquistick NFT" />
      <widget.SubTitle text="Access the game bonding pools" />
      <div className="-mx-4 mb-4 flex">
        {sticksCount && sticksCount > 0 ? (
          <>
            <Stick isConnected={isConnected} loading={!sticks} amount={sticks?.black || 0} media={media.black} />
            <Stick isConnected={isConnected} loading={!sticks} amount={sticks?.gold || 0} media={media.gold} />
            <Stick isConnected={isConnected} loading={!sticks} amount={sticks?.invisible || 0} media={media.invisible} />
          </>
        ) : (
          <BlurredStick />
        )}
      </div>
      <button className="btn-primary mb-8" disabled={!mintButtonEnabled} onClick={onBuy}>
        {mintButtonText}
      </button>
      <a href="https://opensea.io/collection/the-ubiquistick-v3">See your Ubiquisticks on OpenSeas</a>
    </widget.Container>
  );
};

export default UbiquiStick;

const BlurredStick = () => (
  <div className="mx-4 max-w-sm">
    <div className="relative mb-2 rounded-lg border-2 border-solid border-black border-opacity-25 shadow-inner">
      <img className="block h-auto w-full rounded-lg opacity-25 blur grayscale" src="/ubiquistick.jpeg" />
    </div>
  </div>
);

const Stick = ({ amount, media, isConnected, loading }: { amount: number; media?: TokenData; isConnected: boolean; loading: boolean }) => {
  if (amount === 0) return null;
  return (
    <div className="mx-4 max-w-sm">
      <div
        className={cx("relative mb-2 rounded-lg border-2 border-solid border-black border-opacity-25 shadow-inner", { ["ring-1 ring-accent"]: amount !== 0 })}
      >
        {isConnected && loading ? (
          <div className="pointer-events-none absolute flex h-full w-full items-center justify-center">
            <div className="loader"></div>
          </div>
        ) : null}
        <video className="block h-auto w-full rounded-lg" autoPlay loop src={media?.animation_url} poster={media?.image}></video>
      </div>
      <div className="mx-2 flex h-12 items-center text-accent text-opacity-75 drop-shadow-light">
        <div className="flex-grow text-left text-xl">{media?.name}</div>
        {isConnected && !loading && amount > 1 ? <div className="text-3xl">x{amount}</div> : null}
      </div>
    </div>
  );
};
