import { useEffect, useState } from "react";

import { formatEther } from "old-components/lib/format";
import useNamedContracts from "../lib/hooks/contracts/useNamedContracts";
import useManagerManaged from "../lib/hooks/contracts/useManagerManaged";
// import Address from "./ui/Address";
import Balance from "./ui/Balance";
// import { useConnectedContext } from "@/lib/connected";

type State = null | MetapoolMonitorProps;
type MetapoolMonitorProps = {
  metaPoolAddress: string;
  uadBalance: number;
  crvBalance: number;
};

const MetapoolMonitorContainer = () => {
  const { dollarMetapool: metaPool } = useManagerManaged() || {};
  const { curvePool } = useNamedContracts() || {};

  const [metaPoolMonitorProps, setMetapoolMonitorProps] = useState<State>(null);

  useEffect(() => {
    if (metaPool && curvePool) {
      (async function () {
        const [uadBalance, crvBalance] = await Promise.all([metaPool.balances(0), metaPool.balances(1)]);

        setMetapoolMonitorProps({
          metaPoolAddress: metaPool.address,
          uadBalance: +formatEther(uadBalance),
          crvBalance: +formatEther(crvBalance),
        });
      })();
    }
  }, [metaPool, curvePool]);

  return metaPoolMonitorProps && <MetapoolMonitor {...metaPoolMonitorProps} />;
};

const MetapoolMonitor = (props: MetapoolMonitorProps) => {
  return (
    <div className="panel">
      <h2>Metapool Balances</h2>
      <Balance title="uAD" balance={props.uadBalance} />
      <Balance title="CRV" balance={props.crvBalance} />
    </div>
  );
};

export default MetapoolMonitorContainer;
