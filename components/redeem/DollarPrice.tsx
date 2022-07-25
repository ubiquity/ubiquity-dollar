import { BigNumber, ethers } from "ethers";

import { Tooltip } from "@/ui";
import usePrices from "./lib/usePrices";

const roundPrice = (twapPrice: BigNumber): string => parseFloat(ethers.utils.formatEther(twapPrice)).toFixed(8);

const DollarPrice = () => {
  const [twapPrice, spotPrice] = usePrices();

  return (
    <div className="grid grid-cols-2 gap-4">
      <Tooltip content="Exchange price to 3CRV" placement="bottom">
        <div className="text-center">
          <div className="mb-2 text-4xl font-thin opacity-75">${(spotPrice && roundPrice(spotPrice)) || 0}</div>
          <div className="text-sm uppercase tracking-widest">SPOT Price</div>
        </div>
      </Tooltip>
      <Tooltip content="Time Weighted Average Price" placement="bottom">
        <div className="text-center">
          <div className="mb-2 text-4xl font-thin opacity-75">${(twapPrice && roundPrice(twapPrice)) || 0}</div>
          <div className="text-sm uppercase tracking-widest">TWAP Price</div>
        </div>
      </Tooltip>
    </div>
  );
};

export default DollarPrice;
