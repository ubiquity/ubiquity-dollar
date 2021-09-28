import { memo } from "react";
import { connectedWithUserContext } from "./context/connected";
import * as widget from "./ui/widget";

export const YieldFarmingContainer = () => {
  return <YieldFarming />;
};

export const YieldFarming = memo(() => {
  return (
    <widget.Container className="max-w-screen-md !mx-auto relative">
      <widget.Title text="Yield Farming" />
      Deposit uAD or directly zap ETH or CRV to UBQ-farm-token and start farming
    </widget.Container>
  );
});

export default connectedWithUserContext(YieldFarmingContainer);
