import { useState, useEffect } from "react";
import Network from "../network";
import { useConnectedContext } from "../context/connected";
import TransactionsDisplay from "../TransactionsDisplay";
import icons from "../ui/icons";
import { EthAccount } from "../common/types";

const PROD = process.env.NODE_ENV == "production";

type HeaderProps = {
  toggleDrawer: () => void;
};

async function fetchAccount(): Promise<EthAccount | null> {
  const ethereum = (window as any).ethereum;
  if (ethereum?.request) {
    return {
      address: ((await ethereum.request({
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

export default function Header({ toggleDrawer }: HeaderProps) {
  const { setAccount } = useConnectedContext();
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
    <header className="flex h-[60px] items-center justify-center">
      <div className="p-[10px] pl-[20px] absolute left-0" onClick={toggleDrawer}>
        <div className="w-10 cursor-pointer">{icons.svgs.menu}</div>
      </div>
      <div id="logo">
        <span>Ubiquity Dollar</span>
        <span>|</span>
        <span>Dashboard</span>
        <span></span>
      </div>
      <div>
        <span>
          <input type="button" value="Connect Wallet" disabled={connecting} onClick={() => connect()} />
        </span>
      </div>
      <Network />
      <TransactionsDisplay />
      {/* <Account /> */}
    </header>
  );
}
