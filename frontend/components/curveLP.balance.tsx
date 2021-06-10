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

export async function _getLPTokenBalance(
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
    const TOKEN_ADDR = await manager.stableSwapMetaPoolAddress();

    const metapool = IMetaPool__factory.connect(TOKEN_ADDR, provider);
    const rawBalance = await metapool.balanceOf(account);
    if (balances) {
      setBalances({ ...balances, uad3crv: rawBalance });
    }
  }
}

const CurveLPBalance = () => {
  const { account, provider, balances, setBalances } = useConnectedContext();
  if (!account) {
    return null;
  }

  const handleClick = async () =>
    _getLPTokenBalance(
      provider,
      account ? account.address : "",
      balances,
      setBalances
    );
  return (
    <>
      <div className="column-wrap">
        <p className="value">
          {balances ? ethers.utils.formatEther(balances.uad3crv) : "0.0"}
          uAD3CRV-f
        </p>
        <button onClick={handleClick}>Get LP Token Balance</button>
      </div>
    </>
  );
};

export default CurveLPBalance;
