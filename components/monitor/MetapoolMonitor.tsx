import { useEffect, useState } from "react";

import { formatEther } from "@/lib/format";
import useNamedContracts from "../lib/hooks/contracts/useNamedContracts";
import useManagerManaged from "../lib/hooks/contracts/useManagerManaged";
import Address from "./ui/Address";
import Balance from "./ui/Balance";
// import { useConnectedContext } from "@/lib/connected";

type State = null | MetapoolMonitorProps;
type MetapoolMonitorProps = {
  metaPoolAddress: string;
  uadBalance: number;
  crvBalance: number;
  spotPrice: number;
};

const MetapoolMonitorContainer = () => {
  const { dollarMetapool: metaPool } = useManagerManaged() || {};
  const { curvePool } = useNamedContracts() || {};

  const [metaPoolMonitorProps, setMetapoolMonitorProps] = useState<State>(null);

  useEffect(() => {
    if (metaPool && curvePool) {
      (async function () {
        const [uadBalance, crvBalance, rates] = await Promise.all([metaPool.balances(0), metaPool.balances(1), curvePool.get_rates(metaPool.address)]);

        setMetapoolMonitorProps({
          metaPoolAddress: metaPool.address,
          uadBalance: +formatEther(uadBalance),
          crvBalance: +formatEther(crvBalance),
          spotPrice: +formatEther(rates[1]),
        });
      })();
    }
  }, [metaPool, curvePool]);

  return metaPoolMonitorProps && <MetapoolMonitor {...metaPoolMonitorProps} />;
};

const MetapoolMonitor = (props: MetapoolMonitorProps) => {
  return (
    <div>
      <h2>Metapool monitor</h2>
      <Address title="Metapool" address={props.metaPoolAddress} />
      <Balance title="uAD Balance" unit="$" balance={props.uadBalance} />
      <Balance title="CRV Balance" unit="$" balance={props.crvBalance} />
      <Balance title="Spot Price" unit="$" balance={props.spotPrice} />
    </div>
  );
};

export default MetapoolMonitorContainer;
