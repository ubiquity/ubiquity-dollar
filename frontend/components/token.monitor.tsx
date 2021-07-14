import { useEffect, useState } from "react";
import { useConnectedContext } from "./context/connected";
import { formatEther } from "../utils/format";
import * as widget from "./ui/widget";

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
    <widget.Container className="col-span-2">
      <widget.Title text="Token monitor" />
      <widget.SubTitle text="Debt Coupon" />
      <widget.Address
        title="Debt Coupon Manager"
        address={props.debtCouponManagerAddress}
      />
      <widget.Address title="Debt Coupon" address={props.debtCouponAddress} />
      <widget.Balance
        title="Total Outstanding"
        unit="uDebt"
        balance={props.totalOutstandingDebt}
      />
      <widget.Balance
        title="Total Redeemable"
        unit="uDebt"
        balance={props.totalRedeemable}
      />
    </widget.Container>
  );
};

export default TokenMonitorContainer;
