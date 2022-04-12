import { useState, useEffect } from "react";
import Link from "next/link";
import Network from "../network";
import { useConnectedContext } from "../context/connected";
import TransactionsDisplay from "../TransactionsDisplay";
import { EthAccount } from "../common/types";

const PROD = process.env.NODE_ENV == "production";

type HeaderProps = {
  isOpened: boolean;
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

export default function Header({ toggleDrawer, isOpened }: HeaderProps) {
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
    <header className="flex h-16 items-center justify-center">
      {/* {!isOpened && (
        <div className="p-[10px] pl-[20px] absolute left-0" onClick={toggleDrawer}>
          <div className="w-10 cursor-pointer">{icons.svgs.menu}</div>
        </div>
      )} */}
      <Link href="/">
        <a id="logo">
          <span>Ubiquity Dollar</span>
        </a>
      </Link>
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
