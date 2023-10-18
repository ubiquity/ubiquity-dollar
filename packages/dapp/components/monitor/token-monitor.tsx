import { useState } from "react";

import { formatEther } from "@/lib/format";
import useProtocolContracts from "@/components/lib/hooks/contracts/use-protocol-contracts";
// import Address from "./ui/Address";
import Balance from "./ui/balance";
import useEffectAsync from "../lib/hooks/use-effect-async";

type State = null | TokenMonitorProps;
type TokenMonitorProps = {
  creditNftAddress: string;
  creditNftManagerAddress: string;
  totalOutstandingCredit: number;
  totalRedeemable: number;
};

const TokenMonitorContainer = () => {
  const protocolContracts = useProtocolContracts();
  const [tokenMonitorPRops, setTokenMonitorProps] = useState<State>(null);

  useEffectAsync(async () => {
    const contracts = await protocolContracts;
    if (contracts && contracts.creditNft && contracts.creditNftManagerFacet) {
      const [totalOutstandingCredit, totalRedeemable] = await Promise.all([
        contracts.creditNft?.getTotalOutstandingDebt(),
        contracts.dollarToken?.balanceOf(contracts.creditNftManagerFacet.address),
      ]);

      setTokenMonitorProps({
        creditNftAddress: contracts.creditNft.address,
        creditNftManagerAddress: contracts.creditNftManagerFacet.address,
        totalOutstandingCredit: +formatEther(totalOutstandingCredit),
        totalRedeemable: +formatEther(totalRedeemable),
      });
    }
  }, []);

  return tokenMonitorPRops && <TokenMonitor {...tokenMonitorPRops} />;
};

const TokenMonitor = (props: TokenMonitorProps) => {
  return (
    <div className="panel">
      <h2>Credit Monitor</h2>
      <div>
        <Balance title="Total Outstanding" unit="CREDIT-NFT" balance={props.totalOutstandingCredit} />
        {/* <Address title="Credit Nft Manager" address={props.creditNftManagerAddress} /> */}
      </div>
      <div>
        <Balance title="Total Redeemable" unit="CREDIT-NFT" balance={props.totalRedeemable} />
        {/* <Address title="Credit Nft" address={props.creditNftAddress} /> */}
      </div>
    </div>
  );
};

export default TokenMonitorContainer;
