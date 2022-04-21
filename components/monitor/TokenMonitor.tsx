import { useEffect, useState } from "react";

import { useConnectedContext } from "@/lib/connected";
import { formatEther } from "@/lib/format";
import { Container, Title, SubTitle } from "@/ui";

import { Address, Balance } from "./ui";

type State = null | TokenMonitorProps;
type TokenMonitorProps = {
  debtCouponAddress: string;
  debtCouponManagerAddress: string;
  totalOutstandingDebt: number;
  totalRedeemable: number;
};

const TokenMonitorContainer = () => {
  const { contracts } = useConnectedContext();
  const [tokenMonitorPRops, setTokenMonitorProps] = useState<State>(null);

  useEffect(() => {
    if (contracts) {
      (async function () {
        const [totalOutstandingDebt, totalRedeemable] = await Promise.all([
          contracts.debtCouponToken.getTotalOutstandingDebt(),
          contracts.uad.balanceOf(contracts.debtCouponManager.address),
        ]);

        setTokenMonitorProps({
          debtCouponAddress: contracts.debtCouponToken.address,
          debtCouponManagerAddress: contracts.debtCouponManager.address,
          totalOutstandingDebt: +formatEther(totalOutstandingDebt),
          totalRedeemable: +formatEther(totalRedeemable),
        });
      })();
    }
  }, [contracts]);

  return tokenMonitorPRops && <TokenMonitor {...tokenMonitorPRops} />;
};

const TokenMonitor = (props: TokenMonitorProps) => {
  return (
    <Container className="col-span-2">
      <Title text="Token monitor" />
      <SubTitle text="Debt Coupon" />
      <Address title="Debt Coupon Manager" address={props.debtCouponManagerAddress} />
      <Address title="Debt Coupon" address={props.debtCouponAddress} />
      <Balance title="Total Outstanding" unit="uDEBT" balance={props.totalOutstandingDebt} />
      <Balance title="Total Redeemable" unit="uDEBT" balance={props.totalRedeemable} />
    </Container>
  );
};

export default TokenMonitorContainer;
