import { useState, useEffect } from "react";
import Network from "../network";
import { useConnectedContext } from "../context/connected";
import { Transacting } from "../ui/widget";
import icons from "../ui/icons";
import { EthAccount } from "../common/types";

const PROD = process.env.NODE_ENV == "production";

type HeaderProps = {
  toggleDrawer: () => void;
};

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

export default function Header({ toggleDrawer }: HeaderProps) {
  const { setAccount, activeTransactions } = useConnectedContext();
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
    <header className="flex h-[50px] items-center justify-center">
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
      <div className="fixed top-0 right-0 mr-4 mt-4 pointer-events-none">
        {activeTransactions ? activeTransactions.map((transaction, index) => <Transacting key={transaction.id + index} transaction={transaction} />) : null}
      </div>
      {/* <Account /> */}
    </header>
  );
}
