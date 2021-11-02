import { ethers } from "ethers";
import { Dispatch, SetStateAction, useEffect } from "react";
import { ADDRESS } from "../pages/index";
import { UbiquityAlgorithmicDollarManager__factory } from "../contracts/artifacts/types/factories/UbiquityAlgorithmicDollarManager__factory";
import { UbiquityAutoRedeem__factory } from "../contracts/artifacts/types/factories/UbiquityAutoRedeem__factory";
import { useConnectedContext } from "./context/connected";
import { Balances } from "./common/contracts-shortcuts";
import icons from "./ui/icons";

let TOKEN_ADDR: string;
async function _getTokenBalance(
  provider: ethers.providers.Web3Provider | null,
  account: string,
  balances: Balances | null,
  setBalances: Dispatch<SetStateAction<Balances | null>>
): Promise<void> {
  if (provider && account) {
    const manager = UbiquityAlgorithmicDollarManager__factory.connect(ADDRESS.MANAGER, provider);

    TOKEN_ADDR = await manager.autoRedeemTokenAddress();
    const USDC = UbiquityAutoRedeem__factory.connect(TOKEN_ADDR, provider);
    const rawBalance = await USDC.balanceOf(account);
    const usdcBalance = document.getElementById("usdc-balance");
    usdcBalance?.querySelector("a")?.setAttribute("href", `https://etherscan.io/token/${TOKEN_ADDR}${account ? `?a=${account}` : ""}`);
    if (balances) {
      if (!balances.usdc.eq(rawBalance)) setBalances({ ...balances, usdc: rawBalance });
    }
  }
}

const UsdcBalance = () => {
  const { account, provider, balances, setBalances } = useConnectedContext();
  useEffect(() => {
    _getTokenBalance(provider, account ? account.address : "", balances, setBalances);
  }, [balances]);

  if (!account) {
    return null;
  }

  return (
    <>
      <div id="usdc-balance">
        <a target="_blank">
          <div>
            <span>{icons.svgs.usdc}</span>
            <span>{balances ? `${parseInt(ethers.utils.formatEther(balances.usdc))}` : "0"} USDC</span>
          </div>
        </a>
      </div>
    </>
  );
};

export default UsdcBalance;
