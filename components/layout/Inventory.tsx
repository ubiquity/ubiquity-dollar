import Tippy from "@tippyjs/react";
import { BigNumber, ethers } from "ethers";
import { useEffect } from "react";

import useWeb3 from "@/lib/hooks/useWeb3";
import icons from "@/ui/icons";

import useNamedContracts from "../lib/hooks/contracts/useNamedContracts";
import useManagerManaged from "../lib/hooks/contracts/useManagerManaged";
import useBalances from "../lib/hooks/useBalances";
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
    <div id="Inventory">
      <div>
        {/* <span>My inventory</span> */}
        {/* <span> <Network /> </span> */}
      </div>
      <div>
        <div>
          {Number(balances.uad) ? <Token token="uAD" balance={balances.uad} accountAddr={walletAddress} tokenAddr={managedContracts.uad.address} /> : ""}
          {Number(balances.ucr) ? <Token token="uCR" balance={balances.ucr} accountAddr={walletAddress} tokenAddr={managedContracts.uar.address} /> : ""}
          {Number(balances.ucrNft) ? (
            <Token token="uCR-NFT" balance={balances.ucrNft} accountAddr={walletAddress} tokenAddr={managedContracts.debtCouponToken.address} />
          ) : (
            ""
          )}
          {Number(balances.ubq) ? <Token token="UBQ" balance={balances.ubq} accountAddr={walletAddress} tokenAddr={managedContracts.ugov.address} /> : ""}
          {Number(balances.crv) ? <Token token="3CRV" balance={balances.crv} accountAddr={walletAddress} tokenAddr={managedContracts.crvToken.address} /> : ""}
          {Number(balances.uad3crv) ? (
            <Token token="uAD3CRV-f" balance={balances.uad3crv} accountAddr={walletAddress} tokenAddr={managedContracts.metaPool.address} />
          ) : (
            ""
          )}
          {Number(balances.usdc) ? (
            <Token token="USDC" balance={balances.usdc} accountAddr={walletAddress} tokenAddr={namedContracts.usdc.address} decimals={6} />
          ) : (
            ""
          )}
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
  const Svg = tokenSvg[token] || (() => <></>);
  const { ethereum } = window;
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
    <div>
      <div>
        <div>
          {<Svg />}
          <Tippy
            content={
              <div id="tippy">
                <span>Add to Metamask</span>
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
  uAD: () => icons.svgs.uad,
  uCR: () => icons.svgs.ucr,
  "uCR-NFT": () => icons.svgs.ucrNft,
  UBQ: () => icons.svgs.ubq,
  USDC: () => icons.svgs.usdc,
  "3CRV": () => <img alt="" src={icons.base64s["3crv"]} />,
  "uAD3CRV-f": () => <img alt="" src={icons.base64s["uad3crv-f"]} />,
};

export default Inventory;
