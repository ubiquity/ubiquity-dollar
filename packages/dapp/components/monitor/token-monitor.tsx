import { useState } from "react";

import { formatEther } from "@/lib/format";
import useProtocolContracts from "@/components/lib/hooks/contracts/use-protocol-contracts";
import useManagerManaged from "../lib/hooks/contracts/use-manager-managed";
// import Address from "./ui/Address";
import Balance from "./ui/balance";
import useEffectAsync from "../lib/hooks/use-effect-async";

type State = null | TokenMonitorProps;
type TokenMonitorProps = {
  debtCouponAddress: string;
  debtCouponManagerAddress: string;
  totalOutstandingDebt: number;
  totalRedeemable: number;
};

const TokenMonitorContainer = () => {
  const protocolContracts = useProtocolContracts();
  const { creditNft, dollarToken } = useManagerManaged() || {};
  const [tokenMonitorPRops, setTokenMonitorProps] = useState<State>(null);

  useEffectAsync(async () => {
    const contracts = await protocolContracts;
    if (contracts && contracts.creditNftManagerFacet) {
      if (creditNft && dollarToken) {
        const [totalOutstandingDebt, totalRedeemable] = await Promise.all([
          creditNft.getTotalOutstandingDebt(),
          dollarToken.balanceOf(contracts.creditNftManagerFacet.address),
        ]);

        setTokenMonitorProps({
          debtCouponAddress: creditNft.address,
          debtCouponManagerAddress: contracts.creditNftManagerFacet.address,
          totalOutstandingDebt: +formatEther(totalOutstandingDebt),
          totalRedeemable: +formatEther(totalRedeemable),
        });
      }
    }
  }, [creditNft, dollarToken]);

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
