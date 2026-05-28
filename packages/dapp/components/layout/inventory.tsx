import Tippy from "@tippyjs/react";
import { BaseContract, BigNumber, ethers } from "ethers";
import { useState } from "react";
import useEffectAsync from "../lib/hooks/use-effect-async";

import useWeb3 from "@/lib/hooks/use-web-3";
import icons from "@/ui/icons";

import useProtocolContracts from "@/components/lib/hooks/contracts/use-protocol-contracts";
import useNamedContracts from "../lib/hooks/contracts/use-named-contracts";
import useBalances from "../lib/hooks/use-balances";
import { Balances } from "../lib/types";

type ProtocolContracts = NonNullable<Awaited<ReturnType<typeof useProtocolContracts>>>;

const Inventory = () => {
  const { walletAddress } = useWeb3();
  const [balances, refreshBalances] = useBalances();
  const protocolContracts = useProtocolContracts();
  const namedContracts = useNamedContracts();
  const [contracts, setContracts] = useState<ProtocolContracts>();

  useEffectAsync(async () => {
    const contract = await protocolContracts;
    setContracts(contract);

    if (walletAddress) {
      refreshBalances();
    }
  }, [walletAddress]);

  if (!walletAddress || !balances || !namedContracts) {
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
          {/* cspell: disable-next-line */}
          {showIfBalanceExists("dollar", "DOLLAR", "dollarToken")}
          {/* cspell: disable-next-line */}
          {showIfBalanceExists("credit", "CREDIT", "creditToken")}
          {showIfBalanceExists("creditNft", "CREDIT-NFT", "creditNft")}
          {/* cspell: disable-next-line */}
          {showIfBalanceExists("governance", "GOVERNANCE", "governanceToken")}
          {showIfBalanceExists("_3crv", "3crv", "_3crvToken")}
          {showIfBalanceExists("dollar3crv", "dollar3CRV-f", "curveMetaPoolDollarTriPoolLp")}
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
    if (Number(balance) && contracts) {
      let selectedContract = contracts[id as keyof ProtocolContracts] as BaseContract;
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

  const addTokenToWallet = async () => {
    if (typeof window !== "undefined") {
      const ethereum = window.ethereum;
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
  DOLLAR: () => icons.SVGs.dollar,
  // cspell: disable-next-line
  CREDIT: () => icons.SVGs.credit,
  "CREDIT-NFT": () => icons.SVGs.creditNft,
  // cspell: disable-next-line
  GOVERNANCE: () => icons.SVGs.governance,
  USDC: () => icons.SVGs.usdc,
  DAI: () => icons.SVGs.dai,
  USDT: () => icons.SVGs.usdt,
  "3crv": () => <img src={icons.base64s["3crv"]} />,
  "dollar3CRV-f": () => <img src={icons.base64s["dollar3crv-f"]} />,
};

export default Inventory;
