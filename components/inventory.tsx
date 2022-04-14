import { useState, useEffect } from "react";
import Tippy from "@tippyjs/react";
import { ethers, BigNumber } from "ethers";
import { useConnectedContext } from "./context/connected";
import { fetchAccount } from "./common/utils";
import Network from "./network";
import icons from "./ui/icons";

const PROD = process.env.NODE_ENV == "production";

const Inventory = () => {
  const { balances, account, contracts, setAccount } = useConnectedContext();
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

  if (!balances || !contracts || !account)
    return (
      <div className="pointer-events-auto">
        <button
          className="m-0 rounded-none rounded-t-lg bg-accent text-paper opacity-100 hover:bg-accent hover:drop-shadow-accent"
          disabled={connecting}
          onClick={() => connect()}
        >
          Connect Wallet
        </button>
      </div>
    );

  const address = account.address;

  return (
    <div className="pointer-events-auto max-w-screen-lg translate-y-[71%] rounded-t-lg border border-solid border-accent/60 bg-paper transition-transform duration-500 ease-out hover:translate-y-0">
      <div className="relative mb-2 flex text-left uppercase tracking-widest">
        <div className="mt-2 ml-2 flex flex-grow items-center pl-2 text-xs">My inventory</div>
        <Network />
      </div>
      <a className="mb-2 block font-mono text-xs text-white/50" href={`https://etherscan.io/address/${address}`}>
        {address}
      </a>
      <div className="flex justify-center px-2 pb-2">
        <div className="grid grid-cols-4 gap-2">
          <Token token="uAD" balance={balances.uad} accountAddr={address} tokenAddr={contracts.uad.address} />
          <Token token="uAR" balance={balances.uar} accountAddr={address} tokenAddr={contracts.uar.address} />
          <Token token="uDEBT" balance={balances.debtCoupon} accountAddr={address} tokenAddr={contracts.debtCouponToken.address} />
          <Token token="UBQ" balance={balances.ubq} accountAddr={address} tokenAddr={contracts.ugov.address} />
          <Token token="3CRV" balance={balances.crv} accountAddr={address} tokenAddr={contracts.crvToken.address} />
          <Token token="uAD3CRV-f" balance={balances.uad3crv} accountAddr={address} tokenAddr={contracts.metaPool.address} />
          <Token token="USDC" balance={balances.usdc} accountAddr={address} tokenAddr={contracts.usdc.address} decimals={6} />
        </div>
      </div>
    </div>
  );
};

const Token = ({
  balance,
  token,
  tokenAddr,
  accountAddr,
  decimals = 18,
}: {
  balance: BigNumber;
  token: keyof typeof tokenSvg;
  tokenAddr?: string;
  accountAddr?: string;
  decimals?: number;
}) => {
  const Svg = tokenSvg[token] || (() => null);
  const ethereum = (window as any).ethereum;
  const addTokenToWallet = async () => {
    if (!ethereum?.request) {
      return;
    }
    try {
      const base64Img = icons.base64s[token.toLowerCase()];
      const wasAdded = await ethereum.request({
        method: "wallet_watchAsset",
        params: {
          type: "ERC20",
          options: {
            address: accountAddr,
            symbol: token,
            decimals: decimals,
            image: base64Img,
          },
        },
      });
      if (wasAdded) {
        console.log("Thanks for your interest!");
      } else {
        console.log("Your loss!");
      }
    } catch (error) {
      console.log(error);
    }
  };
  return (
    <div className="font-mono text-xs">
      <div className="flex">
        <div className="relative mr-2 flex w-6 flex-shrink-0 items-center text-accent">
          {<Svg />}
          <Tippy
            content={
              <div className="rounded-md border border-solid border-white/10 bg-paper px-4 py-2 text-sm" style={{ backdropFilter: "blur(8px)" }}>
                <p className="text-center text-white/50">Add to Metamask</p>
              </div>
            }
            placement="top"
            duration={0}
          >
            <div
              onClick={addTokenToWallet}
              className="absolute flex h-full w-full cursor-pointer items-center justify-center rounded-md border border-solid border-accent bg-paper text-accent opacity-0 hover:opacity-100"
            >
              +
            </div>
          </Tippy>
        </div>
        <a
          className="flex flex-col text-left leading-none"
          target="_blank"
          href={tokenAddr && accountAddr ? `https://etherscan.io/token/${tokenAddr}?a=${accountAddr}` : ""}
        >
          <div>{token}</div>
          <div>{`${parseInt(ethers.utils.formatUnits(balance, decimals))}`}</div>
        </a>
      </div>
    </div>
  );
};

const tokenSvg = {
  uAD: () => icons.svgs.uad,
  uAR: () => icons.svgs.uar,
  uDEBT: () => icons.svgs.udebt,
  UBQ: () => icons.svgs.ubq,
  USDC: () => icons.svgs.usdc,
  "3CRV": () => <img alt="" src={icons.base64s["3crv"]} />,
  "uAD3CRV-f": () => <img alt="" src={icons.base64s["uad3crv-f"]} />,
};

export default Inventory;
