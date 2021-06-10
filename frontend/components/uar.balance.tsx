import { ethers, BigNumber } from "ethers";

import { UbiquityAutoRedeem__factory } from "../src/types/factories/UbiquityAutoRedeem__factory";
import { IMetaPool__factory } from "../src/types/factories/IMetaPool__factory";
import { Bonding__factory } from "../src/types/factories/Bonding__factory";
import { BondingShare__factory } from "../src/types/factories/BondingShare__factory";
import { UbiquityAlgorithmicDollarManager__factory } from "../src/types/factories/UbiquityAlgorithmicDollarManager__factory";
import { UbiquityAutoRedeem } from "../src/types/UbiquityAutoRedeem";
import { ERC20__factory } from "../src/types/factories/ERC20__factory";

import { ADDRESS } from "../pages/index";
import { useConnectedContext, Balances } from "./context/connected";
import { Dispatch, SetStateAction, useState } from "react";

export async function _getTokenBalance(
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
      balances.uar = rawBalance;
      setBalances(balances);
    }
  }
}

const UarBalance = () => {
  const { account, provider, balances, setBalances } = useConnectedContext();
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
  handleClick();
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
