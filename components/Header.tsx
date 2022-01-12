import { useState, useEffect } from "react";
import { useConnectedContext } from "./context/connected";
import { EthAccount } from "./common/types";
import Account from "./account";
import Network from "./network";

import { Icon } from "./ui/icons";

const PROD = process.env.NODE_ENV == "production";

async function fetchAccount(): Promise<EthAccount | null> {
  if (window.ethereum?.request) {
    return {
      address: ((await window.ethereum.request({
        method: "eth_requestAccounts",
      })) as string[])[0],
      balance: 0,
    };
  } else {
    alert("MetaMask is not installed!");
    console.error("MetaMask is not installed, cannot connect wallet");
    return null;
  }
}

const Header = ({ section, href }: { section: string; href: string }) => {
  const context = useConnectedContext();
  const { setAccount } = context;

  const [connecting, setConnecting] = useState(false);

  const connect = async (): Promise<void> => {
    setConnecting(true);
    setAccount(await fetchAccount());
  };

  if (!PROD) {
    useEffect(() => {
      connect();
    }, []);
  }

  return (
    <header className="p-4 backdrop-blur-xl">
      <div className="flex justify-center mx-auto max-w-screen-md">
        <div className="uppercase tracking-widest text-gray-400 flex items-center flex-grow">
          <a href="/" className="group text-gray-400 hover:text-accent no-underline hover:drop-shadow-light">
            {<Icon icon="uad" className="align-middle h-7 -mt-2 mr-4 fill-gray-400 group-hover:fill-accent" />}
            <span>Ubiquity Dollar</span>
          </a>
          <span className="mx-4">|</span>
          <a href={href} className="text-gray-400 hover:text-accent no-underline hover:drop-shadow-light">
            {section}
          </a>
        </div>
        <div>
          <button disabled={connecting} onClick={() => connect()} className="btn-primary">
            Connect Wallet
          </button>
        </div>
        <div className="flex items-center">
          <Network />
        </div>
      </div>
      <Account />
    </header>
  );
};

export default Header;
