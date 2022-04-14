import { FC } from "react";
import PriceMonitor from "../components/price.monitor";
import MetapoolMonitor from "../components/metapool.monitor";
import TokenMonitor from "../components/token.monitor";

const Monitor: FC = (): JSX.Element => {
  return (
    <div>
      <div className="relative z-20 grid grid-cols-2 gap-4 p-4">
        <PriceMonitor />
        <MetapoolMonitor />
        <TokenMonitor />
      </div>
    </div>
  );
};

export default Monitor;
