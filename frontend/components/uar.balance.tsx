import { ethers, BigNumber } from "ethers";

import { UbiquityAutoRedeem__factory } from "../src/types/factories/UbiquityAutoRedeem__factory";
import { IMetaPool__factory } from "../src/types/factories/IMetaPool__factory";
import { Bonding__factory } from "../src/types/factories/Bonding__factory";
import { BondingShare__factory } from "../src/types/factories/BondingShare__factory";
import { UbiquityAlgorithmicDollarManager__factory } from "../src/types/factories/UbiquityAlgorithmicDollarManager__factory";
import { UbiquityAutoRedeem } from "../src/types/UbiquityAutoRedeem";
import { ERC20__factory } from "../src/types/factories/ERC20__factory";

import { ADDRESS } from "../pages/index";
import { useConnectedContext } from "./context/connected";
import { Dispatch, SetStateAction, useState } from "react";

export async function _getTokenBalance(
  provider: ethers.providers.Web3Provider | undefined,
  account: string,
  setTokenBalance: Dispatch<SetStateAction<string | undefined>>
): Promise<void> {
  console.log("_getTokenBalance");
  // console.log("provider", provider);
  console.log("account", account);
  if (provider && account) {
    const manager = UbiquityAlgorithmicDollarManager__factory.connect(
      ADDRESS.MANAGER,
      provider
    );

    const uARRedeem = await manager.autoRedeemTokenAddress();
    const uAR = UbiquityAutoRedeem__factory.connect(uARRedeem, provider);
    console.log("uARRedeem Address", uARRedeem);
    //console.log("uAD", uAD);
    const rawBalance = await uAR.balanceOf(account);

    const balance = ethers.utils.formatEther(rawBalance);
    console.log("balance", balance);
    setTokenBalance(balance);
  }
}

const UarBalance = () => {
  const { account, provider } = useConnectedContext();
  const [tokenBalance, setTokenBalance] = useState<string>();
  if (!account) {
    return null;
  }

  const handleClick = async () =>
    _getTokenBalance(provider, account ? account.address : "", setTokenBalance);
  handleClick();
  console.log("-------", account.address, tokenBalance);
  return (
    <>
      <div className="column-wrap">
        <p className="value">{tokenBalance} uAR</p>
        <button onClick={handleClick}>Get uAR Token Balance</button>
      </div>
    </>
  );
};

export default UarBalance;
