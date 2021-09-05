import { useEffect, useState } from "react";
import { useConnectedContext } from "./context/connected";
import { formatEther } from "../utils/format";
import * as widget from "./ui/widget";

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
    <widget.Container>
      <widget.Title text="Metapool monitor" />
      <widget.Address title="Metapool" address={props.metaPoolAddress} />
      <widget.Balance title="uAD Balance" unit="$" balance={props.uadBalance} />
      <widget.Balance title="CRV Balance" unit="$" balance={props.crvBalance} />
      <widget.Balance title="Spot Price" unit="$" balance={props.spotPrice} />
    </widget.Container>
  );
};

export default MetapoolMonitorContainer;
