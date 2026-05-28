import { ConnectKitButton } from "connectkit";
import React, { useState } from "react";
import { CSSTransition, SwitchTransition } from "react-transition-group";
import { useAccount } from "wagmi";
import useDidUpdate from "../lib/hooks/use-did-update";
import useWalletAddress from "../lib/hooks/use-wallet-address";
import { note } from "../utils/sounds";

const WalletConnectionWall = ({ children }: { children: React.ReactNode }) => {
  const { status } = useAccount();
  const [walletAddress] = useWalletAddress();
  const [triedConnecting, setTriedConnecting] = useState(false);

  useDidUpdate(() => {
    // If user has tried to connect and failed, play a sound (error sound)
    if (status === "connecting") {
      setTriedConnecting(true);
    }
    if (status === "disconnected" && triedConnecting) {
      note(400);
      setTriedConnecting(false);
    }
    if (status === "connected" && triedConnecting) {
      note(900);
    }
  }, [status, triedConnecting]);

  return (
    <>
      <SwitchTransition>
        <CSSTransition
          classNames="WalletNotConnected__transition"
          key={walletAddress ? "connected" : "disconnected"}
          addEndListener={(node, done) => {
            node.addEventListener("transitionend", done, false);
          }}
          timeout={500}
          unmountOnExit
          mountOnEnter
        >
          {walletAddress ? (
            <div>{children}</div>
          ) : (
            <ConnectKitButton.Custom>
              {({ isConnecting, show }) => (
                <button id="WalletNotConnected" disabled={isConnecting} onClick={show}>
                  <div className="WalletNotConnected__spin">
                    <div className="WalletNotConnected__before">
                      <div></div>
                    </div>
                    <div className="WalletNotConnected__after">
                      <div></div>
                    </div>
                    <div className="WalletNotConnected__center">
                      <div className="WalletNotConnected__logo">
                        <svg className="WalletNotConnected__svg" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 91.57 104.19">
                          <path d="M43.28.67 2.5 24.22A5 5 0 0 0 0 28.55v47.09A5 5 0 0 0 2.5 80l40.78 23.55a5 5 0 0 0 5 0L89.07 80a5 5 0 0 0 2.5-4.33V28.55a5 5 0 0 0-2.5-4.33L48.28.67a5 5 0 0 0-5 0zm36.31 25a2 2 0 0 1 0 3.46l-6 3.48c-2.72 1.57-4.11 4.09-5.34 6.3-.18.33-.36.66-.55 1-3 5.24-4.4 10.74-5.64 15.6C59.71 64.76 58 70.1 50.19 72.09a17.76 17.76 0 0 1-8.81 0c-7.81-2-9.53-7.33-11.89-16.59-1.24-4.86-2.64-10.36-5.65-15.6l-.54-1c-1.23-2.21-2.62-4.73-5.34-6.3l-6-3.47a2 2 0 0 1 0-3.47L43.28 7.6a5 5 0 0 1 5 0zM43.28 96.59 8.5 76.51A5 5 0 0 1 6 72.18v-36.1a2 2 0 0 1 3-1.73l6 3.46c1.29.74 2.13 2.25 3.09 4l.6 1c2.59 4.54 3.84 9.41 5 14.11 2.25 8.84 4.58 18 16.25 20.93a23.85 23.85 0 0 0 11.71 0C63.3 75 65.63 65.82 67.89 57c1.2-4.7 2.44-9.57 5-14.1l.59-1.06c1-1.76 1.81-3.27 3.1-4l5.94-3.45a2 2 0 0 1 3 1.73v36.1a5 5 0 0 1-2.5 4.33L48.28 96.59a5 5 0 0 1-5 0z" />
                        </svg>
                      </div>
                    </div>
                    <div className="WalletNotConnected__text">
                      <div>{isConnecting ? "Connecting..." : "Connect Wallet"}</div>
                    </div>
                  </div>
                </button>
              )}
            </ConnectKitButton.Custom>
          )}
        </CSSTransition>
      </SwitchTransition>
    </>
  );
};

export default WalletConnectionWall;
