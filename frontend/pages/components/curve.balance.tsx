import { ethers, BigNumber } from "ethers";

import { UbiquityAlgorithmicDollar__factory } from "../../src/types/factories/UbiquityAlgorithmicDollar__factory";
import { IMetaPool__factory } from "../../src/types/factories/IMetaPool__factory";
import { Bonding__factory } from "../../src/types/factories/Bonding__factory";
import { BondingShare__factory } from "../../src/types/factories/BondingShare__factory";
import { UbiquityAlgorithmicDollarManager__factory } from "../../src/types/factories/UbiquityAlgorithmicDollarManager__factory";
import { UbiquityAlgorithmicDollarManager } from "../../src/types/UbiquityAlgorithmicDollarManager";
import { ERC20__factory } from "../../src/types/factories/ERC20__factory";

import { ADDRESS } from "../index";
import { useConnectedContext } from "../context/connected";
import { useState } from "react";

export async function _getCurveTokenBalance(
  provider,
  account: string,
  setCurveTokenBalance
): Promise<void> {
  if (provider && account) {
    const manager = UbiquityAlgorithmicDollarManager__factory.connect(
      ADDRESS.MANAGER,
      provider
    );
    const TOKEN_ADDR = await manager.curve3PoolTokenAddress();
    const token = ERC20__factory.connect(TOKEN_ADDR, provider);

    const rawBalance = await token.balanceOf(account);
    const decimals = await token.decimals();

    const balance = ethers.utils.formatUnits(rawBalance, decimals);
    setCurveTokenBalance(balance);
  }
}

const CurveBalance = () => {
  const { account, provider } = useConnectedContext();
  const [curveTokenBalance, setCurveTokenBalance] = useState<string>();
  if (!account) {
    return null;
  }

  const handleClick = async () =>
    _getCurveTokenBalance(
      provider,
      account ? account.address : "",
      setCurveTokenBalance
    );

  return (
    <>
      <button onClick={handleClick}>Get curve Token Balance</button>
      <p>3CRV Balance: {curveTokenBalance}</p>
    </>
  );
};

export default CurveBalance;
