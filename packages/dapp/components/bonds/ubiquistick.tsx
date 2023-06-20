import useTransactionLogger from "../lib/hooks/use-transaction-logger";
import Button from "../ui/_button";
import { OwnedSticks, SticksAllowance, TokenData, TokenMedia } from "./lib/hooks/use-ubiquistick";
import Whitelist from "./whitelist";

// const mockAccount = typeof document !== "undefined" && document.location.search === "?test" ? "0xefC0e701A824943b469a694aC564Aa1efF7Ab7dd" : null;

type UbiquiStickParams = {
  isConnected: boolean;
  sticks: OwnedSticks | null;
  allowance: SticksAllowance | null;
  media: TokenMedia;
  onBuy: () => unknown;
};

const UbiquiStick = ({ isConnected, sticks, allowance, onBuy, media }: UbiquiStickParams) => {
  const [, , transacting] = useTransactionLogger();
  const sticksCount = sticks ? sticks.gold + sticks.black + sticks.invisible : null;

  const isLoaded = !!(sticks && allowance);

  // const blurredOutMessage = !isConnected ? "Connect your wallet" : !isLoaded ? "Checking whitelist" ?

  const mintButtonEnabled = !transacting && sticks && allowance && allowance.count > 0;
  const mintButtonText = !isConnected
    ? "Connect your wallet"
    : !isLoaded
    ? "Checking whitelist"
    : allowance.count === 0 && sticksCount !== 0
    ? "You reached your minting limit"
    : allowance.count === 0 && sticksCount === 0
    ? "You are not whitelisted to mint"
    : `Mint for ${allowance.price} ETH`;

  const isWhitelisted = !!allowance && sticksCount !== null && (allowance.count > 0 || sticksCount > 0);

  const showBlurredOut = !isConnected || !isLoaded || (allowance.count === 0 && sticksCount === 0);

  return (
    <div>
      <h2>The Ubiquistick NFT</h2>
      <h3>Access the bonds</h3>
      <div>
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
      <div>
        <div>
          <Button disabled={!mintButtonEnabled} onClick={onBuy}>
            {mintButtonText}
          </Button>
          <a href="https://opensea.io/collection/the-ubiquistick-v3">See your UbiquiSticks on OpenSeas</a>
        </div>
        {showBlurredOut && <Whitelist isConnected={isConnected} isLoaded={isLoaded} isWhitelisted={isWhitelisted} />}
      </div>
    </div>
  );
};

export default UbiquiStick;

const BlurredStick = () => (
  <div>
    <div>
      <img src="/ubiquistick.jpeg" />
    </div>
  </div>
);

const Stick = ({ amount, media, isConnected, loading }: { amount: number; media?: TokenData; isConnected: boolean; loading: boolean }) => {
  if (amount === 0) return null;
  return (
    <div>
      <div>
        {isConnected && loading ? (
          <div>
            <div></div>
          </div>
        ) : null}
        <video autoPlay loop src={media?.animation_url} poster={media?.image}></video>
      </div>
      <div>
        <div>{media?.name}</div>
        {isConnected && !loading && amount > 1 ? <div>x{amount}</div> : null}
      </div>
    </div>
  );
};
