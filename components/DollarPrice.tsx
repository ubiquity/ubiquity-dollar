import { ethers, BigNumber } from "ethers";
import { parseEther } from "ethers/lib/utils";
import { useState, useEffect } from "react";
import { useConnectedContext } from "./context/connected";

const roundPrice = (twapPrice: BigNumber): string => parseFloat(ethers.utils.formatEther(twapPrice)).toFixed(8);

const DollarPrice = () => {
  const { provider, contracts } = useConnectedContext();
  const [twapPrice, setTwapPrice] = useState<BigNumber | null>(null);
  const [spotPrice, setSpotPrice] = useState<BigNumber | null>(null);

  useEffect(() => {
    if (provider && contracts) {
      (async () => {
        const newTwapPrice = await contracts.twapOracle.consult(await contracts.manager.dollarTokenAddress());
        const newSpotPrice = await contracts.metaPool["get_dy(int128,int128,uint256)"](0, 1, parseEther("1"));
        setTwapPrice(newTwapPrice);
        setSpotPrice(newSpotPrice);
      })();
    }
  }, [provider, contracts]);

  return (
    <div className="mb-4 flex">
      <div>
        <div className="mb-2 bg-gradient-to-r from-white/80 to-transparent bg-clip-text text-4xl text-transparent">${twapPrice && roundPrice(twapPrice)}</div>
        <div className="text-sm uppercase tracking-widest">Time Weighted Average Price</div>
      </div>
      <div>
        <div className="mb-2 bg-gradient-to-r from-white/80 to-transparent bg-clip-text text-4xl text-transparent">${spotPrice && roundPrice(spotPrice)}</div>
        <div className="text-sm uppercase tracking-widest">3CRV Swap Price</div>
      </div>
    </div>
  );
};

export default DollarPrice;
