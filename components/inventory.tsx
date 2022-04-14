import { useState, useEffect } from "react";
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
      <div>
        <button
          className="rounded-none rounded-t-lg m-0 bg-accent opacity-100 text-paper hover:bg-accent hover:drop-shadow-accent"
          disabled={connecting}
          onClick={() => connect()}
        >
          Connect Wallet
        </button>
      </div>
    );

  const address = account.address;

  return (
    <div className="bg-paper rounded-t-lg border border-solid border-accent/60 max-w-screen-lg translate-y-[67%] hover:translate-y-0 transition-transform ease-out">
      <div className="uppercase flex tracking-widest mb-4 relative text-left">
        <div className="flex-grow flex items-center pl-2 text-xs mt-2 ml-2">My inventory</div>
        <Network />
      </div>
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
        <div className="text-accent mr-2 w-6 flex-shrink-0 flex items-center relative">
          {<Svg />}
          <div
            onClick={addTokenToWallet}
            className="absolute h-full w-full border border-solid cursor-pointer border-accent rounded-md bg-paper opacity-0 hover:opacity-100 text-accent flex items-center justify-center"
          >
            +
          </div>
        </div>
        <a
          className="flex flex-col leading-none text-left"
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
