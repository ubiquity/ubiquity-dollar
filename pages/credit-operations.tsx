import { FC, useState } from "react";
import { ethers } from "ethers";

import MigrateButton from "@/components/redeem/MigrateButton";
import DollarPrice from "@/components/redeem/DollarPrice";
import UcrRedeem from "@/components/redeem/UcrRedeem";
import DebtCouponDeposit from "@/components/redeem/DebtCouponDeposit";
import UcrNftRedeem from "@/components/redeem/UcrNftRedeem";
import useManagerManaged from "@/components/lib/hooks/contracts/useManagerManaged";
import useEffectAsync from "@/components/lib/hooks/useEffectAsync";
import useWalletAddress from "@/components/lib/hooks/useWalletAddress";
// import DisabledBlurredMessage from "@/components/ui/DisabledBlurredMessage";
import WalletNotConnected from "@/components/ui/WalletNotConnected";

const PriceStabilization: FC = (): JSX.Element => {
  const [twapPrice, setTwapPrice] = useState<ethers.BigNumber | null>(null);
  const [walletAddress] = useWalletAddress();
  const managedContracts = useManagerManaged();

  useEffectAsync(async () => {
    if (managedContracts) {
      setTwapPrice(await managedContracts.dollarTwapOracle.consult(managedContracts.dollarToken.address));
    }
  }, [managedContracts]);

  // const currentlyAbovePeg = twapPrice?.gte(ethers.utils.parseEther("1")) ?? false;
  let twapInteger = 0;
  if (twapPrice) {
    twapInteger = (twapPrice as unknown as number) / 1e18;
  }

  return walletAddress ? (
    <div id="CreditOperations" data-twap={twapInteger}>
      <DollarPrice />
      <MigrateButton />
      {MintUcr()}
      {RedeemUcr()}
    </div>
  ) : (
    WalletNotConnected
  );
};

export default PriceStabilization;

function MintUcr() {
  return (
    <div id="MintUcr" className="panel">
      <h2>Generate Ubiquity Credit NFTs</h2>
      <aside>When TWAP is below peg</aside>
      <DebtCouponDeposit />
    </div>
  );
}
function RedeemUcr() {
  return (
    <div id="RedeemUcr" className="panel">
      <h2>Redeem Ubiquity Credit NFTs</h2>
      <aside>When TWAP is above peg</aside>
      <div>
        <UcrRedeem />
        <UcrNftRedeem />
      </div>
    </div>
  );
}
