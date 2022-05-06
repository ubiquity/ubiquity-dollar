import { useEffect, useState } from "react";

import { formatEther } from "@/lib/format";
// import { useConnectedContext } from "@/lib/connected";
import { useManagerManaged, useNamedContracts } from "@/lib/hooks";
import { Container, Title } from "@/ui";

import { Address, Balance } from "./ui";

type State = null | MetapoolMonitorProps;
type MetapoolMonitorProps = {
  metaPoolAddress: string;
  uadBalance: number;
  crvBalance: number;
  spotPrice: number;
};

const MetapoolMonitorContainer = () => {
  const { metaPool } = useManagerManaged() || {};
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
    <Container>
      <Title text="Metapool monitor" />
      <Address title="Metapool" address={props.metaPoolAddress} />
      <Balance title="uAD Balance" unit="$" balance={props.uadBalance} />
      <Balance title="CRV Balance" unit="$" balance={props.crvBalance} />
      <Balance title="Spot Price" unit="$" balance={props.spotPrice} />
    </Container>
  );
};

export default MetapoolMonitorContainer;
