import { BigNumber, ethers } from "ethers";

import { Tooltip } from "@/ui";
import usePrices from "./lib/usePrices";
import { Icon } from "../ui";

const roundPrice = (twapPrice: BigNumber): string => parseFloat(ethers.utils.formatEther(twapPrice)).toFixed(8);

const DollarPrice = () => {
  const [twapPrice, spotPrice] = usePrices();

  return (
    <div className="text-center">
      <Tooltip content={`$${(spotPrice && roundPrice(spotPrice)) || 0} (SPOT PRICE)`} placement="bottom">
        <div className="text-center">
          <div className="mb-2 text-4xl font-thin opacity-75">${(twapPrice && roundPrice(twapPrice)) || 0}</div>
          <div className="flex items-center justify-center">
            <div className="mr-1 text-sm uppercase tracking-widest">TWAP Price</div>
            <Icon icon="questionMark" className="w-4" />
          </div>
        </div>
      </Tooltip>
    </div>
  );
};

export default DollarPrice;
