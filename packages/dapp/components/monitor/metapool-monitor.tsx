import { useState } from "react";
import useEffectAsync from "../lib/hooks/use-effect-async";

import { formatEther } from "@/lib/format";
import useNamedContracts from "../lib/hooks/contracts/use-named-contracts";
import useProtocolContracts from "@/components/lib/hooks/contracts/use-protocol-contracts";
// import Address from "./ui/Address";
import Balance from "./ui/balance";
// import { useConnectedContext } from "@/lib/connected";

type State = null | MetapoolMonitorProps;
type MetapoolMonitorProps = {
  metaPoolAddress: string;
  dollarTokenBalance: number;
  curve3CrvTokenBalance: number;
};

const MetapoolMonitorContainer = () => {
  const protocolContracts = useProtocolContracts();
  const { curvePool } = useNamedContracts() || {};

  const [metaPoolMonitorProps, setMetapoolMonitorProps] = useState<State>(null);

  useEffectAsync(async () => {
    const contracts = await protocolContracts;
    const metaPool = contracts.curveMetaPoolDollarTriPoolLp;
    if (metaPool && curvePool) {
      const [dollarTokenBalance, curve3CrvTokenBalance] = await Promise.all([metaPool.balances(0), metaPool.balances(1)]);

      setMetapoolMonitorProps({
        metaPoolAddress: metaPool.address,
        dollarTokenBalance: +formatEther(dollarTokenBalance),
        curve3CrvTokenBalance: +formatEther(curve3CrvTokenBalance),
      });
    }
  }, [curvePool]);

  return metaPoolMonitorProps && <MetapoolMonitor {...metaPoolMonitorProps} />;
};

const MetapoolMonitor = (props: MetapoolMonitorProps) => {
  return (
    <div className="panel">
      <h2>Metapool Balances</h2>
      {/* cspell: disable-next-line */}
      <Balance title="DOLLAR" balance={props.dollarTokenBalance} />
      <Balance title="CRV" balance={props.curve3CrvTokenBalance} />
    </div>
  );
};

export default MetapoolMonitorContainer;
