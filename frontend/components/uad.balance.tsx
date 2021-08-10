import { ethers } from "ethers";
import { Dispatch, SetStateAction, useEffect } from "react";
import { UbiquityAlgorithmicDollar__factory } from "../src/types/factories/UbiquityAlgorithmicDollar__factory";
import { UbiquityAlgorithmicDollarManager } from "../src/types/UbiquityAlgorithmicDollarManager";
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
    const uAD = UbiquityAlgorithmicDollar__factory.connect(
      TOKEN_ADDR,
      provider.getSigner()
    );
    const rawBalance = await uAD.balanceOf(account);
    if (balances) {
      if (!balances.uad.eq(rawBalance))
        setBalances({ ...balances, uad: rawBalance });
    }
  }
}

const UadBalance = () => {
  const {
    account,
    manager,
    provider,
    balances,
    setBalances,
  } = useConnectedContext();

  useEffect(() => {
    _getTokenBalance(
      provider,
      account ? account.address : "",
      manager,
      balances,
      setBalances
    );
  }, [balances]);

  if (!account) {
    return null;
  }

  return (
    <>
      <div id="uad-balance">
        <a
          target="_blank"
          href={`https://etherscan.io/token/${TOKEN_ADDR}${
            account ? `?a=${account.address}` : ""
          }`}
        >
          <div>
            <span>
              <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 75 85.45">
                <path d="m30.13 57.62.35.2L58.31 74 39.36 85a3.75 3.75 0 0 1-3.52.11l-.2-.11L1.86 65.45a3.73 3.73 0 0 1-1.85-3v-6a33 33 0 0 1 30.12 1.17zM9.18 15.77l29.4 17.1.38.22A40.49 40.49 0 0 0 75 35v27.22a3.72 3.72 0 0 1-1.68 3.11l-.18.12-7.34 4.24-31.55-18.35A40.47 40.47 0 0 0 0 48.32v-25.1a3.75 3.75 0 0 1 1.68-3.11l.18-.11zM37.5 0a3.75 3.75 0 0 1 1.64.38l.22.12L73.14 20A3.72 3.72 0 0 1 75 23v3.68a33 33 0 0 1-32.2 0l-.45-.26-25.69-14.97L35.64.5a3.64 3.64 0 0 1 1.62-.5z" />
              </svg>
            </span>
            <span>
              {balances
                ? `${parseInt(ethers.utils.formatEther(balances.uad))}`
                : "0"}{" "}
              uAD
            </span>
          </div>
        </a>
      </div>
    </>
  );
};

export default UadBalance;
