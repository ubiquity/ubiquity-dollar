import { ethers, BigNumber } from "ethers";
import Tippy from "@tippyjs/react";
import { Contracts } from "../contracts";
import { Balances } from "./common/contracts-shortcuts";
import icons from "./ui/icons";

const Inventory = ({ balances, address, contracts }: { balances: Balances; address: string; contracts: Contracts }) => {
  return (
    <div id="inventory-top">
      <div className="grid grid-cols-12">
        <div className="col-span-2">
          <aside>My Inventory</aside>
          <figure></figure>
        </div>
        <div className="col-span-10">
          <div className="grid grid-cols-7">
            <Token id="uad-balance" token="uAD" balance={balances.uad} accountAddr={address} tokenAddr={contracts.uad.address} />
            <Token id="uar-balance" token="uAR" balance={balances.uar} accountAddr={address} tokenAddr={contracts.uar.address} />
            <Token id="debt-coupon-balance" token="uDEBT" balance={balances.debtCoupon} accountAddr={address} tokenAddr={contracts.debtCouponToken.address} />
            <Token id="uar-balance" token="UBQ" balance={balances.ubq} accountAddr={address} tokenAddr={contracts.ugov.address} />
            <Token id="curve-balance" token="3CRV" balance={balances.crv} accountAddr={address} tokenAddr={contracts.crvToken.address} />
            <Token id="curve-lp-balance" token="uAD3CRV-f" balance={balances.uad3crv} accountAddr={address} tokenAddr={contracts.metaPool.address} />
            <Token id="usdc-balance" token="USDC" balance={balances.usdc} accountAddr={address} tokenAddr={contracts.usdc.address} decimals={6} />
          </div>
        </div>
      </div>
    </div>
  );
};

const Token = ({
  id,
  balance,
  token,
  tokenAddr,
  accountAddr,
  decimals = 18,
}: {
  id: string;
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
    <div id={id}>
      <Tippy
        interactive={true}
        appendTo={() => document.body}
        content={
          <div
            className="w-8 h-8 border flex border-accent cursor-pointer border-solid rounded-md"
            style={{ backdropFilter: "blur(8px)" }}
            onClick={addTokenToWallet}
          >
            <p className="text-center m-auto text-accent">+</p>
          </div>
        }
      >
        <a target="_blank" href={tokenAddr && accountAddr ? `https://etherscan.io/token/${tokenAddr}?a=${accountAddr}` : ""}>
          <div className="flex justify-center items-center">
            <span className="text-accent mr-2 w-6 flex-shrink-0">{<Svg />}</span>
            <span className="">
              {`${parseInt(ethers.utils.formatUnits(balance, decimals))}`} {token}
            </span>
          </div>
        </a>
      </Tippy>
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
