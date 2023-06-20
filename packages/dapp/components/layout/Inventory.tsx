import Tippy from "@tippyjs/react";
import { BaseContract, BigNumber, ethers } from "ethers";
import { useEffect } from "react";

import useWeb3 from "@/lib/hooks/use-web-3";
import icons from "@/ui/icons";

import useManagerManaged from "../lib/hooks/contracts/use-manager-managed";
import useNamedContracts from "../lib/hooks/contracts/use-named-contracts";
import useBalances, { Balances } from "../lib/hooks/use-balances";
import { ManagedContracts } from "../lib/hooks/contracts/use-manager-managed";

const Inventory = () => {
  const { walletAddress } = useWeb3();
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
    <div id="inventory">
      <div>
        {/* <span>My inventory</span> */}
        {/* <span> <Network /> </span> */}
      </div>
      <div>
        <div>
          {/* cspell: disable-next-line */}
          {showIfBalanceExists("uad", "uAD", "dollarToken")}
          {/* cspell: disable-next-line */}
          {showIfBalanceExists("ucr", "uCR", "creditToken")}
          {showIfBalanceExists("ucrNft", "uCR-NFT", "creditNft")}
          {/* cspell: disable-next-line */}
          {showIfBalanceExists("ubq", "UBQ", "governanceToken")}
          {showIfBalanceExists("_3crv", "3crv", "_3crvToken")}
          {showIfBalanceExists("uad3crv", "uAD3CRV-f", "dollarMetapool")}
          {showIfBalanceExists("usdc", "USDC", "usdc")}
          {showIfBalanceExists("dai", "DAI", "dai")}
          {showIfBalanceExists("usdt", "USDT", "usdt")}
        </div>
      </div>
    </div>
  );

  function showIfBalanceExists(key: keyof Balances, name: keyof typeof tokenSvg, id: string) {
    const usdcFix = function () {
      if (key == "usdc" || key == "usdt") return 6;
      else return 18;
    };

    if (!balances) {
      console.warn("balances not loaded");
      return null;
    }

    const balance = balances[key];
    if (Number(balance) && managedContracts) {
      let selectedContract = managedContracts[id as keyof ManagedContracts] as BaseContract;
      if (!selectedContract && namedContracts) {
        selectedContract = namedContracts[key as keyof typeof namedContracts];
      }

      return <Token token={name} balance={balance} accountAddr={walletAddress as string} tokenAddr={selectedContract.address} decimals={usdcFix()} />;
    }
  }
};

interface TokenInterface {
  balance: BigNumber;
  token: keyof typeof tokenSvg;
  tokenAddr?: string;
  accountAddr?: string;
  decimals?: number;
}

const Token = ({ balance, token, tokenAddr, accountAddr, decimals = 18 }: TokenInterface) => {
  const Svg = tokenSvg[token] || (() => <></>);

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
          type: "erc-20",
          options: {
            address: tokenAddr,
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
    <div>
      <div>
        <div>
          {<Svg />}
          <Tippy
            content={
              <div id="tippy">
                <span>Add to MetaMask</span>
              </div>
            }
            placement="top"
            duration={0}
          >
            <button onClick={addTokenToWallet}></button>
          </Tippy>
        </div>
        <div>
          <a target="_blank" rel="noopener noreferrer" href={tokenAddr && accountAddr ? `https://etherscan.io/token/${tokenAddr}?a=${accountAddr}` : ""}>
            <span>{`${parseInt(ethers.utils.formatUnits(balance, decimals))}`}</span>
            <span>{token}</span>
          </a>
        </div>
      </div>
    </div>
  );
};

const tokenSvg = {
  // cspell: disable-next-line
  uAD: () => icons.SVGs.uad,
  // cspell: disable-next-line
  uCR: () => icons.SVGs.ucr,
  "uCR-NFT": () => icons.SVGs.ucrNft,
  // cspell: disable-next-line
  UBQ: () => icons.SVGs.ubq,
  USDC: () => icons.SVGs.usdc,
  DAI: () => icons.SVGs.dai,
  USDT: () => icons.SVGs.usdt,
  "3crv": () => <img src={icons.base64s["3crv"]} />,
  "uAD3CRV-f": () => <img src={icons.base64s["uad3crv-f"]} />,
};

export default Inventory;
