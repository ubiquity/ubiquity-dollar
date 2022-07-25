import { useEffect, useState } from "react";

import { formatEther } from "@/lib/format";
import { useDeployedContracts, useManagerManaged } from "@/lib/hooks";
import { Container, SubTitle, Title } from "@/ui";

import { Address, Balance } from "./ui";

type State = null | TokenMonitorProps;
type TokenMonitorProps = {
  debtCouponAddress: string;
  debtCouponManagerAddress: string;
  totalOutstandingDebt: number;
  totalRedeemable: number;
};

const TokenMonitorContainer = () => {
  const { debtCouponManager } = useDeployedContracts() || {};
  const { debtCouponToken, uad } = useManagerManaged() || {};

  const [tokenMonitorPRops, setTokenMonitorProps] = useState<State>(null);

  useEffect(() => {
    if (debtCouponManager && debtCouponToken && uad) {
      (async function () {
        const [totalOutstandingDebt, totalRedeemable] = await Promise.all([
          debtCouponToken.getTotalOutstandingDebt(),
          uad.balanceOf(debtCouponManager.address),
        ]);

        setTokenMonitorProps({
          debtCouponAddress: debtCouponToken.address,
          debtCouponManagerAddress: debtCouponManager.address,
          totalOutstandingDebt: +formatEther(totalOutstandingDebt),
          totalRedeemable: +formatEther(totalRedeemable),
        });
      })();
    }
  }, [debtCouponManager, debtCouponToken, uad]);

  return tokenMonitorPRops && <TokenMonitor {...tokenMonitorPRops} />;
};

const TokenMonitor = (props: TokenMonitorProps) => {
  return (
    <Container className="col-span-2">
      <Title text="Token monitor" />
      <SubTitle text="Debt Coupon" />
      <Address title="Debt Coupon Manager" address={props.debtCouponManagerAddress} />
      <Address title="Debt Coupon" address={props.debtCouponAddress} />
      <Balance title="Total Outstanding" unit="uCR-NFT" balance={props.totalOutstandingDebt} />
      <Balance title="Total Redeemable" unit="uCR-NFT" balance={props.totalRedeemable} />
    </Container>
  );
};

export default TokenMonitorContainer;
