import { useState, useEffect } from "react";
import { ethers, BigNumber } from "ethers";
import { parseEther } from "ethers/lib/utils";

import { Tooltip } from "@/ui";
import { useDeployedContracts, useManagerManaged, useWeb3Provider } from "../lib/hooks";

const roundPrice = (twapPrice: BigNumber): string => parseFloat(ethers.utils.formatEther(twapPrice)).toFixed(8);

const DollarPrice = () => {
  const web3Provider = useWeb3Provider();
  const deployedContracts = useDeployedContracts();
  const managedContracts = useManagerManaged();
  const [twapPrice, setTwapPrice] = useState<BigNumber | null>(null);
  const [spotPrice, setSpotPrice] = useState<BigNumber | null>(null);

  useEffect(() => {
    if (web3Provider && managedContracts && deployedContracts) {
      (async () => {
        const newTwapPrice = await managedContracts.twapOracle.consult(await deployedContracts.manager.dollarTokenAddress());
        const newSpotPrice = await managedContracts.metaPool["get_dy(int128,int128,uint256)"](0, 1, parseEther("1"));
        setTwapPrice(newTwapPrice);
        setSpotPrice(newSpotPrice);
      })();
    }
  }, [web3Provider, managedContracts, deployedContracts]);

  return (
    <div className="mb-4">
      <div className="mb-4">
        <Tooltip content="Time Weighted Average Price" placement="left">
          <div>
            <div className="mb-2 bg-gradient-to-r from-white/80 to-transparent bg-clip-text text-4xl text-transparent">
              ${twapPrice && roundPrice(twapPrice)}
            </div>
            <div className="text-sm uppercase tracking-widest">TWAP Price</div>
          </div>
        </Tooltip>
      </div>
      <div>
        <Tooltip content="Exchange price to 3CRV" placement="left">
          <div>
            <div className="mb-2 bg-gradient-to-r from-white/80 to-transparent bg-clip-text text-4xl text-transparent">
              ${spotPrice && roundPrice(spotPrice)}
            </div>
            <div className="text-sm uppercase tracking-widest">SPOT Price</div>
          </div>
        </Tooltip>
      </div>
    </div>
  );
};

export default DollarPrice;
