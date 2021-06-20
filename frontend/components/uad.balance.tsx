import { ethers } from "ethers";

import { UbiquityAlgorithmicDollar__factory } from "../src/types/factories/UbiquityAlgorithmicDollar__factory";
import { UbiquityAlgorithmicDollarManager } from "../src/types/UbiquityAlgorithmicDollarManager";
import { Balances, useConnectedContext } from "./context/connected";
import { Dispatch, SetStateAction, useEffect } from "react";

export async function _getTokenBalance(
  provider: ethers.providers.Web3Provider | undefined,
  account: string,
  manager: UbiquityAlgorithmicDollarManager | undefined,
  balances: Balances | undefined,
  setBalances: Dispatch<SetStateAction<Balances | undefined>>
): Promise<void> {
  if (provider && account && manager) {
    const uADAddr = await manager.dollarTokenAddress();
    const uAD = UbiquityAlgorithmicDollar__factory.connect(
      uADAddr,
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

  const handleClick = async () =>
    _getTokenBalance(
      provider,
      account ? account.address : "",
      manager,
      balances,
      setBalances
    );

  return (
    <>
      <div>
        <p>
          {balances ? ethers.utils.formatEther(balances.uad) : "0.0"} uAD
        </p>
        <button onClick={handleClick}>Get uAD Token Balance</button>
      </div>
    </>
  );
};

export default UadBalance;
