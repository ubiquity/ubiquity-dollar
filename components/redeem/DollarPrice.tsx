import { BigNumber, ethers } from "ethers";
import Tooltip from "../ui/Tooltip";

import usePrices from "./lib/usePrices";

const roundPrice = (twapPrice: BigNumber): string => parseFloat(ethers.utils.formatEther(twapPrice)).toFixed(8);

const DollarPrice = () => {
  const [twapPrice, spotPrice] = usePrices();

  return (
    <div id="DollarPrice">
      <h2>Ubiquity Dollar Price</h2>
      <Tooltip content="Swap for DAI/USDC/USDT" placement="bottom">
        <div>
          <span>${(spotPrice && roundPrice(spotPrice)) || 0}</span>
          <span>Spot</span>
        </div>
      </Tooltip>
      <Tooltip content="Time weighted average price" placement="bottom">
        <div>
          <span>${(twapPrice && roundPrice(twapPrice)) || 0}</span>
          <span>TWAP</span>
        </div>
      </Tooltip>
    </div>
  );
};

export default DollarPrice;
