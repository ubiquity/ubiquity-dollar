import PriceMonitor from "old-components/monitor/PriceMonitor";
import MetapoolMonitor from "old-components/monitor/MetapoolMonitor";
import TokenMonitor from "old-components/monitor/TokenMonitor";

export default function Monitor() {
  return (
    <>
      <PriceMonitor />
      <MetapoolMonitor />
      <TokenMonitor />
    </>
  );
}
