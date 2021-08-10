import { ethers, BigNumber } from "ethers";

import { useConnectedContext } from "./context/connected";
import { Dispatch, SetStateAction, useEffect } from "react";
import {
  TWAPOracle__factory,
  UbiquityAlgorithmicDollarManager,
} from "../src/types";

export async function _getTwapPrice(
  provider: ethers.providers.Web3Provider | null,
  manager: UbiquityAlgorithmicDollarManager | null,
  twapPrice: BigNumber | null,
  setTwapPrice: Dispatch<SetStateAction<BigNumber | null>>
): Promise<void> {
  if (provider && manager) {
    const uadAdr = await manager.dollarTokenAddress();
    const TWAP_ADDR = await manager.twapOracleAddress();
    const twap = TWAPOracle__factory.connect(TWAP_ADDR, provider);

    const rawPrice = await twap.consult(uadAdr);
    if (twapPrice) {
      if (!twapPrice.eq(rawPrice)) setTwapPrice(rawPrice);
    }
  }
}

const TwapPrice = () => {
  const { provider, manager, twapPrice, setTwapPrice } = useConnectedContext();

  useEffect(() => {
    _getTwapPrice(provider, manager, twapPrice, setTwapPrice);
  });

  if (!manager) {
    return null;
  }

  return (
    <>
      <div id="twap-price">
        <p>${twapPrice && ethers.utils.formatEther(twapPrice)}</p>
        <aside>Time Weighted Average Price</aside>
      </div>
    </>
  );
};

export default TwapPrice;
