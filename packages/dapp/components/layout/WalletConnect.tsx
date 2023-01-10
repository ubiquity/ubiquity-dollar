import { ConnectKitButton } from "connectkit";
import { useDisconnect } from "wagmi";
import Button from "../ui/Button";

const WalletConnect = () => {
  const { disconnect } = useDisconnect();

  return (
    <ConnectKitButton.Custom>
      {({ isConnected, isConnecting, show, address, truncatedAddress, ensName }) => (
        <div id="WalletConnect" className={address ? "connected" : "reset"}>
          {isConnected ? (
            <div>
              <Button onClick={() => disconnect()}>Disconnect</Button>
              <a href={`https://etherscan.io/address/${address}`} target="_blank" rel="noopener noreferrer" id="Address">
                {ensName || truncatedAddress}
              </a>
            </div>
          ) : (
            <Button disabled={isConnecting} onClick={show}>
              {isConnecting ? "Connecting..." : "Connect Wallet"}
            </Button>
          )}
        </div>
      )}
    </ConnectKitButton.Custom>
  );
};

export default WalletConnect;
