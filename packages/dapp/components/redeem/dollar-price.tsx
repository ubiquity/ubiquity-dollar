import { BigNumber, ethers } from "ethers";
import Tooltip from "../ui/tooltip";

import usePrices from "./lib/use-prices";

const roundPrice = (twapPrice: BigNumber): string => parseFloat(ethers.utils.formatEther(twapPrice)).toFixed(8);

const DollarPrice = () => {
  const [twapPrice, spotPrice] = usePrices();

  return (
    <div id="dollar-price" className="panel">
      <h2>Ubiquity Dollar Price</h2>
      <Tooltip content="Swap for DAI/USDC/USDT" placement="bottom">
        <div>
          <span>${(spotPrice && roundPrice(spotPrice)) || "· · ·"}</span>
          <span>Spot</span>
        </div>
      </Tooltip>
      <Tooltip content="Time weighted average price" placement="bottom">
        <div>
          <span>${(twapPrice && roundPrice(twapPrice)) || "· · ·"}</span>
          <span>TWAP</span>
        </div>
      </Tooltip>
      <div style={{ margin: "12px auto 0", fontSize: "12px", opacity: 0.5, backgroundColor: "#ffffff10", padding: "8px 16px", borderRadius: "4px" }}>
        <aside>
          ⚠️ Notice: we are working on raising liquidity and collateral with our partners at <a href="https://apeswap.finance/">ApeSwap</a> in early 2023.
          Please standby for a fully collateralized dollar.
        </aside>
      </div>
    </div>
  );
};

export default DollarPrice;
