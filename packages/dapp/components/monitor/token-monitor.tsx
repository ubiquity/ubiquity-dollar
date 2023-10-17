import { useState } from "react";

import { formatEther } from "@/lib/format";
import useProtocolContracts from "@/components/lib/hooks/contracts/use-protocol-contracts";
import useManagerManaged from "../lib/hooks/contracts/use-manager-managed";
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
  const { creditNft, dollarToken } = useManagerManaged() || {};
  const [tokenMonitorPRops, setTokenMonitorProps] = useState<State>(null);

  useEffectAsync(async () => {
    const contracts = await protocolContracts;
    if (contracts && contracts.creditNftManagerFacet) {
      if (creditNft && dollarToken) {
        const [totalOutstandingCredit, totalRedeemable] = await Promise.all([
          creditNft.getTotalOutstandingCredit(),
          dollarToken.balanceOf(contracts.creditNftManagerFacet.address),
        ]);

        setTokenMonitorProps({
          creditNftAddress: creditNft.address,
          creditNftManagerAddress: contracts.creditNftManagerFacet.address,
          totalOutstandingCredit: +formatEther(totalOutstandingCredit),
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
        <Balance title="Total Outstanding" unit="uCR-NFT" balance={props.totalOutstandingCredit} />
        {/* <Address title="Credit Nft Manager" address={props.creditNftManagerAddress} /> */}
      </div>
      <div>
        <Balance title="Total Redeemable" unit="uCR-NFT" balance={props.totalRedeemable} />
        {/* <Address title="Credit Nft" address={props.creditNftAddress} /> */}
      </div>
    </div>
  );
};

export default TokenMonitorContainer;
