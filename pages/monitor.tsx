import { FC } from "react";
import PriceMonitor from "@/components/monitor/PriceMonitor";
import MetapoolMonitor from "@/components/monitor/MetapoolMonitor";
import TokenMonitor from "@/components/monitor/TokenMonitor";

const Monitor: FC = (): JSX.Element => {
  return (
    <div>
      <div>
        <PriceMonitor />
        <MetapoolMonitor />
        <TokenMonitor />
      </div>
    </div>
  );
};

export default Monitor;
