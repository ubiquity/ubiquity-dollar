import cx from "classnames";
import SectionTitle from "./lib/SectionTitle";
import { OwnedSticks, SticksAllowance } from "./lib/types/state";

// const mockAccount = typeof document !== "undefined" && document.location.search === "?test" ? "0xefC0e701A824943b469a694aC564Aa1efF7Ab7dd" : null;

type UbiquiStickParams = {
  isConnected: boolean;
  sticks: OwnedSticks | null;
  allowance: SticksAllowance | null;
  onBuy: () => any;
};

const UbiquiStick = ({ isConnected, sticks, allowance, onBuy }: UbiquiStickParams) => {
  const sticksCount = sticks ? sticks.gold + sticks.standard : null;

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
      <div className="grid grid-cols-2 gap-8 mb-4">
        <Stick isConnected={isConnected} loading={!sticks} amount={sticks?.standard || 0} imgSrc="ubiquistick.jpeg" name="Standard" />
        <Stick isConnected={isConnected} loading={!sticks} amount={sticks?.gold || 0} imgSrc="ubiquistick.jpeg" name="Gold" />
      </div>
      <button className="btn-primary mb-8" disabled={!mintButtonEnabled} onClick={onBuy}>
        {mintButtonText}
      </button>
      <a href="https://opensea.io/">See your Ubiquisticks on OpenSeas</a>
    </div>
  );
};

export default UbiquiStick;

const Stick = ({ amount, imgSrc, name, isConnected, loading }: { amount: number; imgSrc: string; name: string; isConnected: boolean; loading: boolean }) => {
  return (
    <div className="">
      <div
        className={cx("relative mb-2 rounded-lg shadow-inner border-2 border-solid border-black border-opacity-25", { ["ring-accent ring-1"]: amount !== 0 })}
      >
        {isConnected && loading ? (
          <div className="absolute w-full h-full flex items-center justify-center pointer-events-none">
            <div className="loader"></div>
          </div>
        ) : null}
        <img className={cx("block rounded-lg w-full h-auto", { ["grayscale opacity-25 blur"]: amount === 0 })} src={imgSrc} />
      </div>
      <div className={cx("flex mx-2", { ["text-opacity-25 text-white"]: amount === 0, ["text-opacity-75 text-accent drop-shadow-light"]: amount !== 0 })}>
        <div className="text-3xl flex-grow text-left">{name}</div>
        {isConnected ? <div className="text-3xl">x{loading ? "?" : amount}</div> : null}
      </div>
    </div>
  );
};
