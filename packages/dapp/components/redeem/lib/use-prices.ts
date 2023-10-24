import useProtocolContracts from "@/components/lib/hooks/contracts/use-protocol-contracts";
import useWeb3 from "@/components/lib/hooks/use-web-3";
import { BigNumber, utils } from "ethers";
import { useEffect, useState } from "react";

const usePrices = (): [BigNumber | null, BigNumber | null, () => Promise<void>] => {
  const protocolContracts = useProtocolContracts();
  const { provider } = useWeb3();

  const [twapPrice, setTwapPrice] = useState<BigNumber | null>(null);
  const [spotPrice, setSpotPrice] = useState<BigNumber | null>(null);

  async function refreshPrices() {
    try {
      if (!protocolContracts || !provider) {
        return;
      }

      const contracts = await protocolContracts;

      if (contracts.curveMetaPoolDollarTriPoolLp) {
        const dollarTokenAddress = await contracts.managerFacet?.dollarTokenAddress();
        const newTwapPrice = await contracts.twapOracleDollar3poolFacet?.consult(dollarTokenAddress);
        const newSpotPrice = await contracts.curveMetaPoolDollarTriPoolLp["get_dy(int128,int128,uint256)"](0, 1, utils.parseEther("1"));
        setTwapPrice(newTwapPrice);
        setSpotPrice(newSpotPrice);
      }
    } catch (error) {
      console.log("Error in refreshPrices: ", error);
    }
  }

  useEffect(() => {
    refreshPrices();
  }, [provider]);

  return [twapPrice, spotPrice, refreshPrices];
};

export default usePrices;
