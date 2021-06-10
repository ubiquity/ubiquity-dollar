import { ethers, BigNumber } from "ethers";

import { UbiquityAlgorithmicDollar__factory } from "../src/types/factories/UbiquityAlgorithmicDollar__factory";
import { IMetaPool__factory } from "../src/types/factories/IMetaPool__factory";
import { Bonding__factory } from "../src/types/factories/Bonding__factory";
import { BondingShare__factory } from "../src/types/factories/BondingShare__factory";
import { UbiquityAlgorithmicDollarManager__factory } from "../src/types/factories/UbiquityAlgorithmicDollarManager__factory";
import { UbiquityAlgorithmicDollarManager } from "../src/types/UbiquityAlgorithmicDollarManager";
import { ERC20__factory } from "../src/types/factories/ERC20__factory";

import { ADDRESS } from "../pages/index";
import { Balances, useConnectedContext } from "./context/connected";
import { Dispatch, SetStateAction, useState } from "react";

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
  handleClick();
  return (
    <>
      <div className="column-wrap">
        <p className="value">
          {balances ? ethers.utils.formatEther(balances.uad) : "0.0"} uAD
        </p>
        <button onClick={handleClick}>Get uAD Token Balance</button>
      </div>
    </>
  );
};

export default UadBalance;
