import { useEffect, useState } from "react";
import useWeb3 from "../lib/hooks/useWeb3";
import Button from "../ui/Button";
import Icon from "../ui/Icon";
import Tooltip from "../ui/Tooltip";

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
      <div id="WalletConnect">
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
            <Button disabled={connecting} onClick={() => promptConnectWallet()}>
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
        <span>{text}</span>
        <span>
          <img src={`/providers-icons/${icon}.svg`} />
        </span>
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
      <div>
        {/* <div> */}
        {/* <h2>Provider</h2> */}
        {/* </div> */}
        <div>
          <a>
            <Btn
              text="Metamask"
              icon="metamask"
              onClick={
                metamaskInstalled
                  ? connectMetamask
                  : () => window.open("https://chrome.google.com/webstore/detail/metamask/nkbihfbeogaeaoehlefnkodbefgpgknn?hl=es", "_blank")
              }
            />
          </a>
          <a>
            <Btn text="Hardhat" icon="hardhat" onClick={promptForWalletAddress} />
          </a>
        </div>
      </div>
    </div>
  );
}
