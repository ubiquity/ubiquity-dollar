import Tippy from "@tippyjs/react";
import { BaseContract, BigNumber, ethers } from "ethers";
import { useEffect } from "react";

import useWeb3 from "@/lib/hooks/useWeb3";
import icons from "@/ui/icons";

import useManagerManaged from "../lib/hooks/contracts/useManagerManaged";
import useNamedContracts from "../lib/hooks/contracts/useNamedContracts";
import useBalances, { Balances } from "../lib/hooks/useBalances";
import { ManagedContracts } from "../lib/hooks/contracts/useManagerManaged";

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
    <div id="Inventory">
      <div>
        {/* <span>My inventory</span> */}
        {/* <span> <Network /> </span> */}
      </div>
      <div>
        <div>
          {showIfBalanceExists("uad", "uAD", "dollarToken")}
          {showIfBalanceExists("ucr", "uCR", "creditToken")}
          {showIfBalanceExists("ucrNft", "uCR-NFT", "creditNft")}
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

  function showIfBalanceExists(key: keyof Balances | keyof typeof namedContracts, name: keyof typeof tokenSvg, id: string) {
    const usdcFix = function () {
      if (key == "usdc" || key == "usdt") return 6;
      else return 18;
    };

    const balance = (balances as Balances)[key];
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
          type: "ERC20",
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
          <a target="_blank" href={tokenAddr && accountAddr ? `https://etherscan.io/token/${tokenAddr}?a=${accountAddr}` : ""}>
            <span>{`${parseInt(ethers.utils.formatUnits(balance, decimals))}`}</span>
            <span>{token}</span>
          </a>
        </div>
      </div>
    </div>
  );
};

const tokenSvg = {
  uAD: () => icons.SVGs.uad,
  uCR: () => icons.SVGs.ucr,
  "uCR-NFT": () => icons.SVGs.ucrNft,
  UBQ: () => icons.SVGs.ubq,
  USDC: () => icons.SVGs.usdc,
  DAI: () => icons.SVGs.dai,
  USDT: () => icons.SVGs.usdt,
  "3crv": () => <img src={icons.base64s["3crv"]} />,
  "uAD3CRV-f": () => <img src={icons.base64s["uad3crv-f"]} />,
};

export default Inventory;
