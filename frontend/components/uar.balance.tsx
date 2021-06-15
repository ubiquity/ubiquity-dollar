import { ethers } from "ethers";

import { UbiquityAutoRedeem__factory } from "../src/types/factories/UbiquityAutoRedeem__factory";
import { UbiquityAlgorithmicDollarManager__factory } from "../src/types/factories/UbiquityAlgorithmicDollarManager__factory";
import { ADDRESS } from "../pages/index";
import { useConnectedContext, Balances } from "./context/connected";
import { Dispatch, SetStateAction, useEffect } from "react";

async function _getTokenBalance(
  provider: ethers.providers.Web3Provider | undefined,
  account: string,
  balances: Balances | undefined,
  setBalances: Dispatch<SetStateAction<Balances | undefined>>
): Promise<void> {
  if (provider && account) {
    const manager = UbiquityAlgorithmicDollarManager__factory.connect(
      ADDRESS.MANAGER,
      provider
    );

    const uARRedeem = await manager.autoRedeemTokenAddress();
    const uAR = UbiquityAutoRedeem__factory.connect(uARRedeem, provider);
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

  const handleClick = async () =>
    _getTokenBalance(
      provider,
      account ? account.address : "",
      balances,
      setBalances
    );
  return (
    <>
      <div className="column-wrap">
        <p className="value">
          {balances ? ethers.utils.formatEther(balances.uar) : "0.0"} uAR
        </p>
        <button onClick={handleClick}>Get uAR Token Balance</button>
      </div>
    </>
  );
};

export default UarBalance;
