import Tippy from "@tippyjs/react";
import { BigNumber, ethers } from "ethers";
import { useEffect } from "react";

import { useBalances, useManagerManaged, useNamedContracts } from "@/lib/hooks";
import useWeb3 from "@/lib/hooks/useWeb3";
import icons from "@/ui/icons";

import Network from "./Network";

const Inventory = () => {
  const [{ walletAddress }] = useWeb3();
  const [balances, refreshBalances] = useBalances();
  const managedContracts = useManagerManaged();
  const namedContracts = useNamedContracts();

  useEffect(() => {
    if (walletAddress) {
      refreshBalances();
    }
  }, [walletAddress]);

  if (!walletAddress || !balances || !managedContracts || !namedContracts) {
    return null;
  }

  return (
    <div className="pointer-events-auto max-w-screen-lg translate-y-[65%] rounded-t-lg border border-b-0 border-solid border-accent/60 bg-paper transition-transform duration-500 ease-out hover:translate-y-0">
      <div className="relative mb-2 flex text-left uppercase tracking-widest">
        <div className="mt-2 ml-2 flex flex-grow items-center pl-2 text-xs">My inventory</div>
        <Network />
      </div>
      <div className="flex justify-center px-2 pb-2">
        <div className="grid grid-cols-4 gap-2">
          <Token token="uAD" balance={balances.uad} accountAddr={walletAddress} tokenAddr={managedContracts.uad.address} />
          <Token token="uCR" balance={balances.ucr} accountAddr={walletAddress} tokenAddr={managedContracts.uar.address} />
          <Token token="uCR-NFT" balance={balances.ucrNft} accountAddr={walletAddress} tokenAddr={managedContracts.debtCouponToken.address} />
          <Token token="UBQ" balance={balances.ubq} accountAddr={walletAddress} tokenAddr={managedContracts.ugov.address} />
          <Token token="3CRV" balance={balances.crv} accountAddr={walletAddress} tokenAddr={managedContracts.crvToken.address} />
          <Token token="uAD3CRV-f" balance={balances.uad3crv} accountAddr={walletAddress} tokenAddr={managedContracts.metaPool.address} />
          <Token token="USDC" balance={balances.usdc} accountAddr={walletAddress} tokenAddr={namedContracts.usdc.address} decimals={6} />
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
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  const ethereum = window.ethereum;
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
  uCR: () => icons.svgs.ucr,
  "uCR-NFT": () => icons.svgs.ucrNft,
  UBQ: () => icons.svgs.ubq,
  USDC: () => icons.svgs.usdc,
  "3CRV": () => <img alt="" src={icons.base64s["3crv"]} />,
  "uAD3CRV-f": () => <img alt="" src={icons.base64s["uad3crv-f"]} />,
};

export default Inventory;
