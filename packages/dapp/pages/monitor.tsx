import { FC } from "react";
import PriceMonitor from "@/components/monitor/price-monitor";
import MetapoolMonitor from "@/components/monitor/metapool-monitor";
import TokenMonitor from "@/components/monitor/token-monitor";

const Monitor: FC = (): JSX.Element => {
  return (
    <>
      <PriceMonitor />
      <MetapoolMonitor />
      <TokenMonitor />
    </>
  );
};

export default Monitor;
