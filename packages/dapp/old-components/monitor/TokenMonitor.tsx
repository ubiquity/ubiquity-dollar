import { useEffect, useState } from "react";

import { formatEther } from "old-components/lib/format";
import useDeployedContracts from "../lib/hooks/contracts/useDeployedContracts";
import useManagerManaged from "../lib/hooks/contracts/useManagerManaged";
// import Address from "./ui/Address";
import Balance from "./ui/Balance";

type State = null | TokenMonitorProps;
type TokenMonitorProps = {
  debtCouponAddress: string;
  debtCouponManagerAddress: string;
  totalOutstandingDebt: number;
  totalRedeemable: number;
};

const TokenMonitorContainer = () => {
  const { creditNftManager } = useDeployedContracts() || {};
  const { creditNft: debtCouponToken, dollarToken: uad } = useManagerManaged() || {};

  const [tokenMonitorPRops, setTokenMonitorProps] = useState<State>(null);

  useEffect(() => {
    if (creditNftManager && debtCouponToken && uad) {
      (async function () {
        const [totalOutstandingDebt, totalRedeemable] = await Promise.all([debtCouponToken.getTotalOutstandingDebt(), uad.balanceOf(creditNftManager.address)]);

        setTokenMonitorProps({
          debtCouponAddress: debtCouponToken.address,
          debtCouponManagerAddress: creditNftManager.address,
          totalOutstandingDebt: +formatEther(totalOutstandingDebt),
          totalRedeemable: +formatEther(totalRedeemable),
        });
      })();
    }
  }, [creditNftManager, debtCouponToken, uad]);

  return tokenMonitorPRops && <TokenMonitor {...tokenMonitorPRops} />;
};

const TokenMonitor = (props: TokenMonitorProps) => {
  return (
    <div className="panel">
      <h2>Credit Monitor</h2>
      <div>
        <Balance title="Total Outstanding" unit="uCR-NFT" balance={props.totalOutstandingDebt} />
        {/* <Address title="Debt Coupon Manager" address={props.debtCouponManagerAddress} /> */}
      </div>
      <div>
        <Balance title="Total Redeemable" unit="uCR-NFT" balance={props.totalRedeemable} />
        {/* <Address title="Debt Coupon" address={props.debtCouponAddress} /> */}
      </div>
    </div>
  );
};

export default TokenMonitorContainer;
