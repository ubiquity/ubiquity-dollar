import cx from "classnames";
import SectionTitle from "./lib/SectionTitle";
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
    <div className="party-container flex flex-col items-center">
      <SectionTitle title="The Ubiquistick NFT" subtitle="Access the game bonding pools" />
      <div className="flex mb-4 -mx-4">
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
    </div>
  );
};

export default UbiquiStick;

const BlurredStick = () => (
  <div className="mx-4 max-w-sm">
    <div className="relative mb-2 rounded-lg shadow-inner border-2 border-solid border-black border-opacity-25">
      <img className="block rounded-lg w-full h-auto grayscale opacity-25 blur" src="/ubiquistick.jpeg" />
    </div>
  </div>
);

const Stick = ({ amount, media, isConnected, loading }: { amount: number; media?: TokenData; isConnected: boolean; loading: boolean }) => {
  if (amount === 0) return null;
  return (
    <div className="mx-4 max-w-sm">
      <div
        className={cx("relative mb-2 rounded-lg shadow-inner border-2 border-solid border-black border-opacity-25", { ["ring-accent ring-1"]: amount !== 0 })}
      >
        {isConnected && loading ? (
          <div className="absolute w-full h-full flex items-center justify-center pointer-events-none">
            <div className="loader"></div>
          </div>
        ) : null}
        <video className="block rounded-lg w-full h-auto" autoPlay loop src={media?.animation_url} poster={media?.image}></video>
      </div>
      <div className="flex mx-2 h-12 text-opacity-75 text-accent drop-shadow-light items-center">
        <div className="text-xl flex-grow text-left">{media?.name}</div>
        {isConnected && !loading && amount > 1 ? <div className="text-3xl">x{amount}</div> : null}
      </div>
    </div>
  );
};
