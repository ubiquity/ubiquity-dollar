import { useEffect, useState } from "react";

import { formatEther } from "@/lib/format";
import { useConnectedContext } from "@/lib/connected";
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
