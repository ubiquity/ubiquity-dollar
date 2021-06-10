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
import { Dispatch, SetStateAction, useEffect, useState } from "react";

async function _getCurveTokenBalance(
  provider: ethers.providers.Web3Provider | undefined,
  account: string,
  manager: UbiquityAlgorithmicDollarManager | undefined,
  balances: Balances | undefined,
  setBalances: Dispatch<SetStateAction<Balances | undefined>>
): Promise<void> {
  if (provider && account && manager) {
    const TOKEN_ADDR = await manager.curve3PoolTokenAddress();
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

  const handleClick = async () =>
    _getCurveTokenBalance(
      provider,
      account ? account.address : "",
      manager,
      balances,
      setBalances
    );
  return (
    <>
      <div className="column-wrap">
        <p className="value">
          {balances ? ethers.utils.formatEther(balances.crv) : "0.0"} 3CRV
        </p>
        <button onClick={handleClick}>Get curve Token Balance</button>
      </div>
    </>
  );
};

export default CurveBalance;
