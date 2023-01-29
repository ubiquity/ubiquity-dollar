import PriceMonitor from "@/components/monitor/PriceMonitor";
import MetapoolMonitor from "@/components/monitor/MetapoolMonitor";
import TokenMonitor from "@/components/monitor/TokenMonitor";

export default function Monitor() {
  return (
    <>
      <PriceMonitor />
      <MetapoolMonitor />
      <TokenMonitor />
    </>
  );
}
