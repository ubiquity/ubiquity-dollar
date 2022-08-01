import { useWeb3 } from "@/lib/hooks";
import { Button, Container, Icon, Title, Tooltip } from "@/ui";
import { useEffect, useState } from "react";

const PROD = process.env.NODE_ENV == "production";

const WalletConnect = () => {
  const [walletModal, setWalletModal] = useState(false);
  const [{ walletAddress, providerMode, connecting, metamaskInstalled }, { disconnect, connectMetamask }] = useWeb3();

  const promptConnectWallet = () => {
    setWalletModal(true);
  };

  useEffect(() => {
    if (walletModal && PROD) {
      connectMetamask();
    }
  }, [walletModal]);

  return (
    <>
      {walletModal && !walletAddress && !PROD && <Modal metamaskInstalled={metamaskInstalled} onClose={() => setWalletModal(false)} />}
      <div>
        {walletAddress ? (
          <div>
            <Tooltip
              content={
                <>
                  {walletAddress}
                  <br />
                  Provider: {providerMode}
                </>
              }
              placement="bottom"
            >
              <a href={`https://etherscan.io/address/${walletAddress}`} target="_blank">
                <Icon icon="help" />
              </a>
            </Tooltip>
            <Button onClick={() => disconnect()}>Disconnect</Button>
          </div>
        ) : (
          <>
            <Button styled="accent" disabled={connecting} onClick={() => promptConnectWallet()}>
              {connecting ? "Connecting..." : "Connect Wallet"}
            </Button>
          </>
        )}
      </div>
    </>
  );
};

export default WalletConnect;

function Modal({ onClose, metamaskInstalled }: { onClose: () => void; metamaskInstalled: boolean }) {
  const [{ provider }, { connectMetamask, connectJsonRpc }] = useWeb3();

  console.log("PROVIDER!", provider);

  function Btn({ text, onClick, icon }: { text: string; icon: string; onClick: () => void }) {
    return (
      <div onClick={() => onClick()}>
        <div>
          <img src={"/providers-icons/" + icon + ".svg"} />
        </div>
        <span>{text}</span>
      </div>
    );
  }

  function promptForWalletAddress() {
    const promptedWallet = prompt("Wallet address to use and impersonate?");
    if (promptedWallet) {
      connectJsonRpc(promptedWallet);
    }
  }

  return (
    <div>
      <div onClick={() => onClose()}></div>
      <Container>
        <Title text="Connect wallet" />
        <div>
          <Btn
            text="Metamask"
            icon="metamask"
            onClick={
              metamaskInstalled
                ? connectMetamask
                : () => window.open("https://chrome.google.com/webstore/detail/metamask/nkbihfbeogaeaoehlefnkodbefgpgknn?hl=es", "_blank")
            }
          />
          <Btn text="Hardhat node" icon="hardhat" onClick={promptForWalletAddress} />
        </div>
      </Container>
    </div>
  );
}
