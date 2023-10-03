import { getIMetaPoolContract } from "@/components/utils/contracts";
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
      if(!protocolContracts || !provider) {
        return;
      }

      const dollarTokenAddress = protocolContracts.managerFacet && await protocolContracts.managerFacet.dollarTokenAddress();
      const newTwapPrice = protocolContracts.twapOracleDollar3poolFacet && await protocolContracts.twapOracleDollar3poolFacet.consult(dollarTokenAddress);
      
      const dollar3poolMarket = protocolContracts.managerFacet && await protocolContracts.managerFacet.stableSwapMetaPoolAddress();
      const dollarMetapool = getIMetaPoolContract(dollar3poolMarket, provider)
      const newSpotPrice = await dollarMetapool["get_dy(int128,int128,uint256)"](0, 1, utils.parseEther("1"));
      setTwapPrice(newTwapPrice);
      setSpotPrice(newSpotPrice);
    } catch (error) {
      console.log("Error in refreshPrices: ", error)
    }
  }

  useEffect(() => {
    refreshPrices();
  }, [protocolContracts, provider]);

  return [twapPrice, spotPrice, refreshPrices];
};

export default usePrices;
