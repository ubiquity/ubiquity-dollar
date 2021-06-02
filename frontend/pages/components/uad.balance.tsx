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

export async function _getTokenBalance(
  provider,
  account: string,
  setTokenBalance
): Promise<void> {
  console.log("_getTokenBalance");
  // console.log("provider", provider);
  console.log("account", account);
  if (provider && account) {
    const uAD = UbiquityAlgorithmicDollar__factory.connect(
      ADDRESS.UAD,
      provider.getSigner()
    );
    console.log("ADDRESS.UAD", ADDRESS.UAD);
    //console.log("uAD", uAD);
    const rawBalance = await uAD.balanceOf(account);
    console.log("rawBalance", rawBalance);

    const decimals = await uAD.decimals();
    console.log("decimals", decimals);
    const balance = ethers.utils.formatUnits(rawBalance, decimals);
    console.log("balance", balance);
    setTokenBalance(balance);
  }
}

const UadBalance = () => {
  const { account, provider } = useConnectedContext();
  const [tokenBalance, setTokenBalance] = useState<string>();
  if (!account) {
    return null;
  }

  const handleClick = async () =>
    _getTokenBalance(provider, account ? account.address : "", setTokenBalance);

  return (
    <>
      <button onClick={handleClick}>Get uAD Token Balance</button>
      <p>uAD Balance: {tokenBalance}</p>
    </>
  );
};

export default UadBalance;
