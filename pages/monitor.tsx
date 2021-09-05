import { FC } from "react";
import { useConnectedContracts } from "../components/context/connected";
import PriceMonitor from "../components/price.monitor";
import MetapoolMonitor from "../components/metapool.monitor";
import TokenMonitor from "../components/token.monitor";

const Monitor: FC = (): JSX.Element => {
  useConnectedContracts();

  return (
    <div>
      <div className="fixed h-screen w-screen z-10">
        <div id="grid"></div>
      </div>
      <div className="relative z-20 grid sm:grid-cols-2 lg:grid-cols-4 gap-4 p-4">
        <PriceMonitor />
        <MetapoolMonitor />
        <TokenMonitor />
      </div>
    </div>
  );
};

export default Monitor;
