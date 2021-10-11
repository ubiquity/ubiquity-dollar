import { ethers } from "ethers";
import { Dispatch, SetStateAction, useEffect } from "react";
import { UbiquityAlgorithmicDollar__factory } from "../contracts/artifacts/types/factories/UbiquityAlgorithmicDollar__factory";
import { UbiquityAlgorithmicDollarManager } from "../contracts/artifacts/types/UbiquityAlgorithmicDollarManager";
import { Balances, useConnectedContext } from "./context/connected";

let TOKEN_ADDR: string;

export async function _getTokenBalance(
  provider: ethers.providers.Web3Provider | null,
  account: string,
  manager: UbiquityAlgorithmicDollarManager | null,
  balances: Balances | null,
  setBalances: Dispatch<SetStateAction<Balances | null>>
): Promise<void> {
  if (provider && account && manager) {
    TOKEN_ADDR = await manager.dollarTokenAddress();
    const uAD = UbiquityAlgorithmicDollar__factory.connect(TOKEN_ADDR, provider.getSigner());
    const rawBalance = await uAD.balanceOf(account);
    if (balances) {
      if (!balances.uad.eq(rawBalance)) setBalances({ ...balances, uad: rawBalance });
    }
  }
}

const UadBalance = () => {
  const { account, manager, provider, balances, setBalances } = useConnectedContext();

  useEffect(() => {
    _getTokenBalance(provider, account ? account.address : "", manager, balances, setBalances);
  }, [balances]);

  if (!account) {
    return null;
  }

  return (
    <>
      <div id="uad-balance">
        <a target="_blank" href={`https://etherscan.io/token/${TOKEN_ADDR}${account ? `?a=${account.address}` : ""}`}>
          <div>
            <span>
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 131.66 150">
                <path d="m54.5 97.23.51.29L95.45 121l-27.54 16a5.44 5.44 0 0 1-5.11.16l-.29-.16-49.1-28.35a5.42 5.42 0 0 1-2.69-4.36v-8.7a48.08 48.08 0 0 1 43.78 1.7zm-30.45-60.7 42.73 24.8.55.32a59 59 0 0 0 52.38 2.77v39.48a5.4 5.4 0 0 1-2.44 4.51l-.26.18-10.67 6.14-45.85-26.61a58.92 58.92 0 0 0-49.78-4.38v-36.4a5.42 5.42 0 0 1 2.44-4.51l.26-.16zm41.16-22.87a5.43 5.43 0 0 1 2.38.55l.32.17L117 42.67a5.4 5.4 0 0 1 2.7 4.35v5.33a48 48 0 0 1-46.8 0l-.64-.35-37.34-21.73 27.59-15.89a5.25 5.25 0 0 1 2.35-.72zm66.45 27.11a6.54 6.54 0 0 0-3.27-5.66L69.1.87a6.58 6.58 0 0 0-6.54 0L3.27 35.11A6.54 6.54 0 0 0 0 40.77v68.46a6.57 6.57 0 0 0 3.27 5.67l59.29 34.23a6.58 6.58 0 0 0 6.54 0l59.29-34.23a6.57 6.57 0 0 0 3.27-5.67z" />
              </svg>
            </span>
            <span>{balances ? `${parseInt(ethers.utils.formatEther(balances.uad))}` : "0"} uAD</span>
          </div>
        </a>
      </div>
    </>
  );
};

export default UadBalance;
