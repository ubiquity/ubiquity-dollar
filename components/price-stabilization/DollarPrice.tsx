import { ethers, BigNumber } from "ethers";

import { Tooltip } from "@/ui";
import usePrices from "./lib/usePrices";

const roundPrice = (twapPrice: BigNumber): string => parseFloat(ethers.utils.formatEther(twapPrice)).toFixed(8);

const DollarPrice = () => {
  const [twapPrice, spotPrice] = usePrices();

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
