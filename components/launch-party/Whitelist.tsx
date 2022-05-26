import Vip from "@/ui/vip.svg";
import { ButtonLink } from "@/ui";

const WhitelistContainer = ({ isConnected, isLoaded, isWhitelisted }: { isConnected: boolean; isLoaded: boolean; isWhitelisted: boolean }) => {
  const status = !isConnected ? "not-connected" : !isLoaded ? "loading" : isWhitelisted ? "whitelisted" : "not-whitelisted";

  return <Whitelist status={status} />;
};

export type WhitelistStatus = "not-connected" | "loading" | "whitelisted" | "not-whitelisted";

const TWITTER_MESSAGE = "Tweeting to be eligible for the #ubiquistick NFT whitelist @UbiquityDAO";

const Whitelist = ({ status }: { status: WhitelistStatus }) => {
  return (
    <div className="absolute top-0 right-0 bottom-0 left-0 flex items-center  justify-center rounded-lg border-4 border-dashed border-white/25 bg-white/10">
      <div className="flex">
        <div>
          <Vip className="h-20 fill-white px-8 py-4" />
        </div>
        <div className="flex flex-grow items-center justify-center text-center">
          {(() => {
            switch (status) {
              case "not-connected":
                return <h2 className="m-0 text-base uppercase tracking-widest">Connect your wallet to check if you are on the whitelist</h2>;
              case "loading":
                return (
                  <>
                    <div className="loader mr-4"></div>
                    <h2 className="m-0 text-base uppercase tracking-widest">
                      Checking if you are
                      <br />
                      on the whitelist
                    </h2>
                  </>
                );
              case "whitelisted":
                return (
                  <div>
                    <h2 className="m-0 mb-2 text-base uppercase tracking-widest">You are whitelisted</h2>
                    <p className="m-0 font-light tracking-wide">You may mint a UbiquiStick and use the exclusive pools</p>
                  </div>
                );
              case "not-whitelisted":
                return (
                  <div>
                    <h2 className="m-0 mb-2 text-base uppercase tracking-widest">You are not whitelisted</h2>
                    <p className="m-0 mb-4 font-light tracking-wide">In order to participate you need to be on the whitelist</p>
                    <ButtonLink target="_blank" href={`https://twitter.com/intent/tweet?text=${encodeURIComponent(TWITTER_MESSAGE)}`}>
                      I want in
                    </ButtonLink>
                  </div>
                );
            }
          })()}
        </div>
      </div>
    </div>
  );
};

export default WhitelistContainer;
