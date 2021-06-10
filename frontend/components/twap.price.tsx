import { ethers, BigNumber } from "ethers";

import { UbiquityAlgorithmicDollar__factory } from "../src/types/factories/UbiquityAlgorithmicDollar__factory";
import { IMetaPool__factory } from "../src/types/factories/IMetaPool__factory";
import { Bonding__factory } from "../src/types/factories/Bonding__factory";
import { BondingShare__factory } from "../src/types/factories/BondingShare__factory";
import { UbiquityAlgorithmicDollarManager__factory } from "../src/types/factories/UbiquityAlgorithmicDollarManager__factory";
import { UbiquityAlgorithmicDollarManager } from "../src/types/UbiquityAlgorithmicDollarManager";
import { ERC20__factory } from "../src/types/factories/ERC20__factory";

import { ADDRESS } from "../pages/index";
import { useConnectedContext } from "./context/connected";
import { Dispatch, SetStateAction, useEffect, useState } from "react";
import { TWAPOracle, TWAPOracle__factory } from "../src/types";

export async function _getTwapPrice(
  provider: ethers.providers.Web3Provider | undefined,
  uadAdr: string,
  curTwapPrice: string,
  setTwapPrice: Dispatch<SetStateAction<string | undefined>>
): Promise<void> {
  if (provider && uadAdr) {
    const manager = UbiquityAlgorithmicDollarManager__factory.connect(
      ADDRESS.MANAGER,
      provider
    );
    const TWAP_ADDR = await manager.twapOracleAddress();
    const twap = TWAPOracle__factory.connect(TWAP_ADDR, provider);

    const rawPrice = await twap.consult(uadAdr);

    const price = ethers.utils.formatEther(rawPrice);
    if (!(price === curTwapPrice)) setTwapPrice(price);
  }
}

const TwapPrice = () => {
  const { provider, uAD } = useConnectedContext();
  const [twapPrice, setTwapPrice] = useState<string>();
  useEffect(() => {
    _getTwapPrice(
      provider,
      uAD ? uAD.address : "",
      twapPrice ?? "",
      setTwapPrice
    );
  });

  if (!uAD) {
    return null;
  }

  const handleClick = async () =>
    _getTwapPrice(
      provider,
      uAD ? uAD.address : "",
      twapPrice ?? "",
      setTwapPrice
    );

  return (
    <>
      <div className="row">
        <button onClick={handleClick}>Get TWAP Price</button>
        <p className="value">uAD TWAP Price: {twapPrice} $</p>
      </div>
    </>
  );
};

export default TwapPrice;
