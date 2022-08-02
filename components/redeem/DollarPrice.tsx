import { BigNumber, ethers } from "ethers";
import Tooltip from "../ui/Tooltip";

import usePrices from "./lib/usePrices";

const roundPrice = (twapPrice: BigNumber): string => parseFloat(ethers.utils.formatEther(twapPrice)).toFixed(8);

const DollarPrice = () => {
  const [twapPrice, spotPrice] = usePrices();

  return (
    <div id="DollarPrice">
      <Tooltip content="Exchange price to 3CRV" placement="bottom">
        <div>
          <div>${(spotPrice && roundPrice(spotPrice)) || 0}</div>
          <div>Spot Price</div>
        </div>
      </Tooltip>
      <Tooltip content="Time Weighted Average Price" placement="bottom">
        <div>
          <div>${(twapPrice && roundPrice(twapPrice)) || 0}</div>
          <div>TWAP Price</div>
        </div>
      </Tooltip>
    </div>
  );
};

export default DollarPrice;
