import { ethers } from "ethers";
import { Dispatch, SetStateAction, useEffect } from "react";
import { ADDRESS } from "../pages/index";
import { UbiquityAlgorithmicDollarManager__factory } from "../src/types/factories/UbiquityAlgorithmicDollarManager__factory";
import { UbiquityAutoRedeem__factory } from "../src/types/factories/UbiquityAutoRedeem__factory";
import { Balances, useConnectedContext } from "./context/connected";

let TOKEN_ADDR: string;
async function _getTokenBalance(
  provider: ethers.providers.Web3Provider | null,
  account: string,
  balances: Balances | null,
  setBalances: Dispatch<SetStateAction<Balances | null>>
): Promise<void> {
  if (provider && account) {
    const manager = UbiquityAlgorithmicDollarManager__factory.connect(
      ADDRESS.MANAGER,
      provider
    );
    // console.log({
    //   "manager.governanceTokenAddress": await manager.governanceTokenAddress(),
    // });
    TOKEN_ADDR = await manager.governanceTokenAddress();
    const uarAddress = await manager.autoRedeemTokenAddress();
    const uAR = UbiquityAutoRedeem__factory.connect(uarAddress, provider);
    const rawBalance = await uAR.balanceOf(account);
    if (balances) {
      if (!balances.uar.eq(rawBalance))
        setBalances({ ...balances, uar: rawBalance });
    }
  }
}

const UarBalance = () => {
  const { account, provider, balances, setBalances } = useConnectedContext();
  useEffect(() => {
    _getTokenBalance(
      provider,
      account ? account.address : "",
      balances,
      setBalances
    );
  }, [balances]);

  if (!account) {
    return null;
  }

  return (
    <>
      <div id="ubq-balance">
        <a
          target="_blank"
          href={`https://etherscan.io/token/${TOKEN_ADDR}${
            account ? `?a=${account.address}` : ""
          }`}
        >
          <div>
            <span>
              <svg
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 91.57 104.19"
              >
                <path d="M43.28.67 2.5 24.22A5 5 0 0 0 0 28.55v47.09A5 5 0 0 0 2.5 80l40.78 23.55a5 5 0 0 0 5 0L89.07 80a5 5 0 0 0 2.5-4.33V28.55a5 5 0 0 0-2.5-4.33L48.28.67a5 5 0 0 0-5 0zm36.31 25a2 2 0 0 1 0 3.46l-6 3.48c-2.72 1.57-4.11 4.09-5.34 6.3-.18.33-.36.66-.55 1-3 5.24-4.4 10.74-5.64 15.6C59.71 64.76 58 70.1 50.19 72.09a17.76 17.76 0 0 1-8.81 0c-7.81-2-9.53-7.33-11.89-16.59-1.24-4.86-2.64-10.36-5.65-15.6l-.54-1c-1.23-2.21-2.62-4.73-5.34-6.3l-6-3.47a2 2 0 0 1 0-3.47L43.28 7.6a5 5 0 0 1 5 0zM43.28 96.59 8.5 76.51A5 5 0 0 1 6 72.18v-36.1a2 2 0 0 1 3-1.73l6 3.46c1.29.74 2.13 2.25 3.09 4l.6 1c2.59 4.54 3.84 9.41 5 14.11 2.25 8.84 4.58 18 16.25 20.93a23.85 23.85 0 0 0 11.71 0C63.3 75 65.63 65.82 67.89 57c1.2-4.7 2.44-9.57 5-14.1l.59-1.06c1-1.76 1.81-3.27 3.1-4l5.94-3.45a2 2 0 0 1 3 1.73v36.1a5 5 0 0 1-2.5 4.33L48.28 96.59a5 5 0 0 1-5 0z" />
              </svg>
            </span>
            <span>
              {balances
                ? `${parseInt(ethers.utils.formatEther(balances.ubq))}`
                : "0"}{" "}
              UBQ
            </span>{" "}
          </div>
        </a>
      </div>
    </>
  );
};

export default UarBalance;
