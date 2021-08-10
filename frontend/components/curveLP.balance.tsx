import { ethers } from "ethers";
import { Dispatch, SetStateAction, useEffect } from "react";
import { ADDRESS } from "../pages/index";
import { IMetaPool__factory } from "../src/types/factories/IMetaPool__factory";
import { UbiquityAlgorithmicDollarManager__factory } from "../src/types/factories/UbiquityAlgorithmicDollarManager__factory";
import { Balances, useConnectedContext } from "./context/connected";

let TOKEN_ADDR: string;

export async function _getLPTokenBalance(
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
    TOKEN_ADDR = await manager.stableSwapMetaPoolAddress();

    const metapool = IMetaPool__factory.connect(TOKEN_ADDR, provider);
    const rawBalance = await metapool.balanceOf(account);
    if (balances) {
      if (!balances.uad3crv.eq(rawBalance))
        setBalances({ ...balances, uad3crv: rawBalance });
    }
  }
}

const CurveLPBalance = () => {
  const { account, provider, balances, setBalances } = useConnectedContext();
  useEffect(() => {
    _getLPTokenBalance(
      provider,
      account ? account.address : "",
      balances,
      setBalances
    );
  }, [balances?.uad3crv]);
  if (!account) {
    return null;
  }

  return (
    <>
      <div id="curve-lp-balance">
        <a
          target="_blank"
          href={`https://etherscan.io/token/${TOKEN_ADDR}${
            account ? `?a=${account.address}` : ""
          }`}
        >
          <div>
            <span>
              <img
                alt=""
                src="data:image/webp;base64,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"
              />
            </span>
            <span>
              {balances
                ? `${parseInt(ethers.utils.formatEther(balances.uad3crv))}`
                : "0"}{" "}
              uAD3CRV-f
            </span>
          </div>
        </a>
      </div>
    </>
  );
};

export default CurveLPBalance;
