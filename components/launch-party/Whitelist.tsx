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
          <svg className="h-20 fill-white px-8 py-4" version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" x="0px" y="0px" viewBox="0 0 512 512">
            <g>
              <g>
                <path
                  d="M368.183,55.339l-42.484-27.747l-10.41,29.127l-41.311,14.524c-5.513-2.405-11.59-3.747-17.978-3.747
			s-12.466,1.342-17.978,3.747l-41.311-14.525L186.3,27.593l-42.483,27.747L0,67.841l80.624,416.566h350.753L512,67.841
			L368.183,55.339z M298.532,97.567l20.64-7.257c1.728,5.712,3.248,13.297,3.248,22.31c0,9.013-1.521,16.599-3.248,22.31
			l-20.64-7.257c1.672-4.711,2.591-9.775,2.591-15.053S300.204,102.278,298.532,97.567z M256.001,100.473
			c6.698,0,12.146,5.449,12.146,12.145s-5.449,12.146-12.146,12.146s-12.145-5.449-12.145-12.146S249.303,100.473,256.001,100.473z
			 M192.829,90.309l20.64,7.258c-1.672,4.711-2.591,9.775-2.591,15.053c-0.001,5.276,0.918,10.341,2.591,15.052l-20.64,7.257
			c-1.728-5.711-3.248-13.297-3.248-22.31S191.101,96.021,192.829,90.309z M140.862,208.727l28.227-28.415l-51.569-68.411
			l42.803-27.956c-2.108,7.872-3.72,17.523-3.72,28.674c0,30.508,12.042,49.854,13.416,51.959l7.07,10.841l10.424-3.665
			l34.152,152.704L140.862,208.727z M218.84,160.74l19.181-6.744c5.513,2.405,11.59,3.747,17.979,3.747s12.466-1.343,17.979-3.748
			l19.18,6.744l-37.159,166.153L218.84,160.74z M371.14,208.726l-80.804,115.732l34.152-152.703l10.423,3.665l7.071-10.841
			c1.373-2.105,13.415-21.451,13.415-51.959c0-11.151-1.612-20.802-3.72-28.673l42.802,27.954l-51.567,68.41L371.14,208.726z"
                />
              </g>
            </g>
          </svg>
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
