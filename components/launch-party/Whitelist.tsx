import Vip from "../ui/vip.svg";

export type WhitelistStatus = "not-connected" | "connected" | "whitelisted" | "not-whitelisted";

const Whitelist = ({ status }: { status: WhitelistStatus }) => {
  return (
    <div className="party-container">
      <div className="flex">
        <div>
          <Vip className="fill-white h-20 px-8 py-4" />
        </div>
        <div className="flex-grow flex items-center justify-center text-center">
          {(() => {
            switch (status) {
              case "not-connected":
                return <h2 className="m-0 tracking-widest uppercase text-base">Connect your wallet to check if you are on the whitelist</h2>;
              case "connected":
                return (
                  <>
                    <div className="loader mr-4"></div>
                    <h2 className="m-0 tracking-widest uppercase text-base">
                      Checking if you are
                      <br />
                      on the whitelist
                    </h2>
                  </>
                );
              case "whitelisted":
                return (
                  <div>
                    <h2 className="m-0 mb-2 tracking-widest uppercase text-base">You are whitelisted</h2>
                    <p className="m-0 font-light tracking-wide">You may mint a UbiquiStick and use the exclusive pools</p>
                  </div>
                );
              case "not-whitelisted":
                return (
                  <div>
                    <h2 className="m-0 mb-2 tracking-widest uppercase text-base">You are not whitelisted</h2>
                    <p className="m-0 mb-4 font-light tracking-wide">In order to participate you need to be on the whitelist</p>
                    <a
                      className="btn-primary"
                      target="_blank"
                      href="https://twitter.com/intent/tweet?text=%40UbiquityDAO%20I%20want%20to%20be%20whitelisted%20for%20the%20launch%20party%20https%3A%2F%2Fuad.ubq.fi%2Flaunch-party"
                    >
                      I want in
                    </a>
                  </div>
                );
            }
          })()}
        </div>
      </div>
    </div>
  );
};

export default Whitelist;
