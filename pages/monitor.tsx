import { FC } from "react";
import PriceMonitor from "@/components/monitor/PriceMonitor";
import MetapoolMonitor from "@/components/monitor/MetapoolMonitor";
import TokenMonitor from "@/components/monitor/TokenMonitor";

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
