import { ConnectKitButton } from "connectkit";
import { useDisconnect } from "wagmi";
import Button from "../ui/button";

const WalletConnect = () => {
  const { disconnect } = useDisconnect();

  return (
    <ConnectKitButton.Custom>
      {({ isConnected, isConnecting, show, address, truncatedAddress, ensName }) => (
        <div id="WalletConnect" className={address ? "connected" : "reset"}>
          {isConnected ? (
            <div className="wallet-connect__disconnect">
              <div>
                <a href={`https://etherscan.io/address/${address}`} target="_blank" rel="noopener noreferrer" id="Address">
                  {ensName || truncatedAddress}
                </a>
              </div>
              <div>
                <div id="Disconnect">
                  <button className="svg-background" onClick={() => disconnect()}></button>
                </div>
              </div>
            </div>
          ) : (
            <Button className="wallet-connect__connect" disabled={isConnecting} onClick={show}>
              {isConnecting ? "Connecting..." : "Connect Wallet"}
            </Button>
          )}
        </div>
      )}
    </ConnectKitButton.Custom>
  );
};

export default WalletConnect;
