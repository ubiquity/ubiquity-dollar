import { ethers } from "ethers";
import { Dispatch, SetStateAction, useEffect } from "react";
import { ERC20__factory } from "../src/types/factories/ERC20__factory";
import { UbiquityAlgorithmicDollarManager } from "../src/types/UbiquityAlgorithmicDollarManager";
import { Balances, useConnectedContext } from "./context/connected";

let TOKEN_ADDR: string;

async function _getCurveTokenBalance(
  provider: ethers.providers.Web3Provider | null,
  account: string,
  manager: UbiquityAlgorithmicDollarManager | null,
  balances: Balances | null,
  setBalances: Dispatch<SetStateAction<Balances | null>>
): Promise<void> {
  if (provider && account && manager) {
    TOKEN_ADDR = await manager.curve3PoolTokenAddress();
    const token = ERC20__factory.connect(TOKEN_ADDR, provider);

    const rawBalance = await token.balanceOf(account);
    if (balances) {
      if (!balances.crv.eq(rawBalance))
        setBalances({ ...balances, crv: rawBalance });
    }
  }
}

const CurveBalance = () => {
  const {
    account,
    provider,
    manager,
    balances,
    setBalances,
  } = useConnectedContext();
  useEffect(() => {
    _getCurveTokenBalance(
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
      <div id="curve-balance">
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
                ? `${parseInt(ethers.utils.formatEther(balances.crv))}`
                : "0"}{" "}
              3CRV
            </span>
          </div>
        </a>
      </div>
    </>
  );
};

export default CurveBalance;
