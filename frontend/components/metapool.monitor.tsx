import { useEffect, useState } from "react";
import { useConnectedContext } from "./context/connected";
import { formatEther } from "../utils/format";

type State = null | MetapoolMonitorProps;
type MetapoolMonitorProps = {
  metaPoolAddress: string;
  uadBalance: number;
  crvBalance: number;
  spotPrice: number;
};

const MetapoolMonitorContainer = () => {
  const { contracts } = useConnectedContext();
  const [metaPoolMonitorProps, setMetapoolMonitorProps] = useState<State>(null);

  useEffect(() => {
    if (contracts) {
      (async function () {
        const [uadBalance, crvBalance, rates] = await Promise.all([
          contracts.metaPool.balances(0),
          contracts.metaPool.balances(1),
          contracts.curvePool.get_rates(contracts.metaPool.address),
        ]);

        setMetapoolMonitorProps({
          metaPoolAddress: contracts.metaPool.address,
          uadBalance: +formatEther(uadBalance),
          crvBalance: +formatEther(crvBalance),
          spotPrice: +formatEther(rates[1]),
        });
      })();
    }
  }, [contracts]);

  return metaPoolMonitorProps && <MetapoolMonitor {...metaPoolMonitorProps} />;
};

const MetapoolMonitor = (props: MetapoolMonitorProps) => {
  return (
    <div
      border="1 solid white/10"
      text="white/50"
      className="!block !mx-0 !py-8 px-4 tracking-wide bg-blur rounded-md"
    >
      <div className="text-center uppercase mb-2 tracking-widest text-sm">
        Metapool monitor
      </div>
      <div className="text-center break-words text-xs mb-8">
        {props.metaPoolAddress}
      </div>
      <div className="mb-8">
        <div className="flex">
          <div className="text-white/75 w-1/2">uAD Balance</div>
          <div>
            <span className="text-white/75">$ </span>
            {props.uadBalance}
          </div>
        </div>
        <div className="flex">
          <div className="text-white/75 w-1/2">CRV Balance</div>
          <div>
            <span className="text-white/75">$ </span> {props.crvBalance}
          </div>
        </div>
        <div className="flex">
          <div className="text-white/75 w-1/2">Spot Price</div>
          <div>
            <span className="text-white/75">$ </span>
            {props.spotPrice}
          </div>
        </div>
      </div>
    </div>
  );
};

export default MetapoolMonitorContainer;
