import { ethers } from "ethers";
import { Dispatch, SetStateAction, useEffect } from "react";
import { ADDRESS } from "../pages/index";
import { UbiquityAlgorithmicDollarManager__factory } from "../contracts/artifacts/types/factories/UbiquityAlgorithmicDollarManager__factory";
import { UbiquityAutoRedeem__factory } from "../contracts/artifacts/types/factories/UbiquityAutoRedeem__factory";
import { useConnectedContext } from "./context/connected";
import { Balances } from "./common/contractsShortcuts";

let TOKEN_ADDR: string;
async function _getTokenBalance(
  provider: ethers.providers.Web3Provider | null,
  account: string,
  balances: Balances | null,
  setBalances: Dispatch<SetStateAction<Balances | null>>
): Promise<void> {
  if (provider && account) {
    const manager = UbiquityAlgorithmicDollarManager__factory.connect(ADDRESS.MANAGER, provider);
    // console.log({
    //   "manager.governanceTokenAddress": await manager.governanceTokenAddress(),
    // });
    TOKEN_ADDR = await manager.governanceTokenAddress();
    const uarAddress = await manager.autoRedeemTokenAddress();
    const uAR = UbiquityAutoRedeem__factory.connect(uarAddress, provider);
    const rawBalance = await uAR.balanceOf(account);
    if (balances) {
      if (!balances.uar.eq(rawBalance)) setBalances({ ...balances, uar: rawBalance });
    }
  }
}

const UarBalance = () => {
  const { account, provider, balances, setBalances } = useConnectedContext();
  useEffect(() => {
    _getTokenBalance(provider, account ? account.address : "", balances, setBalances);
  }, [balances]);

  if (!account) {
    return null;
  }

  return (
    <>
      <div id="ubq-balance">
        <a target="_blank" href={`https://etherscan.io/token/${TOKEN_ADDR}${account ? `?a=${account.address}` : ""}`}>
          <div>
            <span>
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 132 151">
                <path d="M132 41.1c0-2.3-1.3-4.5-3.3-5.7L69.4 1.2c-1-.6-2.1-.9-3.3-.9-1.1 0-2.3.3-3.3.9L3.6 35.4c-2 1.2-3.3 3.3-3.3 5.7v68.5c0 2.3 1.3 4.5 3.3 5.7l59.3 34.2c2 1.2 4.5 1.2 6.5 0l59.3-34.2c2-1.2 3.3-3.3 3.3-5.7V41.1zm-11.9 62.5c0 2.7-1.4 5.2-3.7 6.5l-46.6 27.5c-1.1.7-2.4 1-3.7 1s-2.5-.3-3.7-1l-46.6-27.5c-2.3-1.3-3.7-3.8-3.7-6.5V54.1c0-1.2.6-2.4 1.7-3 1.1-.6 2.3-.6 3.4 0l8 4.7c1.9 1.1 3 3.3 4.4 5.8.3.5.5 1 .8 1.4 3.5 6.3 5.2 13 6.8 19.5 3 11.9 6 24.2 21.3 28.2 5 1.3 10.4 1.3 15.4 0 15.2-4 18.3-16.3 21.3-28.2C96.8 76 98.5 69.3 102 63c.3-.5.5-1 .8-1.4 1.3-2.5 2.5-4.6 4.4-5.8l8-4.7c1-.6 2.3-.6 3.4 0s1.7 1.7 1.7 3v49.5zM62.6 13.7c2.2-1.3 4.9-1.3 7.1 0L110 37.6c1 .6 1.6 1 1.6 2.2 0 1.2-.6 1.9-1.6 2.5l-7.7 4.6c-3.4 2-5.1 5.2-6.6 8.1l-.1.2c-.2.4-.4.7-.6 1.1-3.8 6.8-6.6 14-8.2 20.4C83.6 89.1 82.4 97.3 72 100c-1.9.5-3.9.7-5.8.7-2 0-3.9-.3-5.8-.7C50 97.3 48.7 89.1 45.6 76.6 44 70.2 41.2 63 37.4 56.2c-.2-.3-.4-.7-.6-1l-.1-.3c-1.5-2.8-3.3-6.1-6.6-8.1l-7.7-4.6c-1-.6-1.6-1.3-1.6-2.5s.6-1.6 1.6-2.2l40.2-23.8z" />
              </svg>
            </span>
            <span>{balances ? `${parseInt(ethers.utils.formatEther(balances.ubq))}` : "0"} UBQ</span>{" "}
          </div>
        </a>
      </div>
    </>
  );
};

export default UarBalance;
