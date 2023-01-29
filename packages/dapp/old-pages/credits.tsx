import { FC, useState } from "react";
import MigrateButton from "old-components/redeem/MigrateButton";
import DollarPrice from "old-components/redeem/DollarPrice";
import UcrRedeem from "old-components/redeem/UcrRedeem";
import UcrNftGenerator from "old-components/redeem/DebtCouponDeposit";
import UcrNftRedeem from "old-components/redeem/UcrNftRedeem";

import useManagerManaged from "old-components/lib/hooks/contracts/useManagerManaged";

import useEffectAsync from "old-components/lib/hooks/useEffectAsync";
// import DisabledBlurredMessage from "@/components/ui/DisabledBlurredMessage";
import WalletConnectionWall from "old-components/ui/WalletConnectionWall";

const PriceStabilization: FC = (): JSX.Element => {
  const [twapInteger, setTwapInteger] = useState<number>(0);
  const managedContracts = useManagerManaged();

  useEffectAsync(async () => {
    if (managedContracts) {
      const twapPrice = await managedContracts.dollarTwapOracle.consult(managedContracts.dollarToken.address);
      if (twapPrice) {
        const twapPriceInteger = (twapPrice as unknown as number) / 1e18;
        setTwapInteger(twapPriceInteger);
      }
    }
  }, [managedContracts]);

  return (
    <WalletConnectionWall>
      <div id="CreditOperations" data-twap={twapInteger}>
        <DollarPrice />
        <MigrateButton />
        <div id="MintUcr" className="panel">
          <h2>Generate Ubiquity Credit NFTs</h2>
          <aside>When TWAP is below peg</aside>
          <UcrNftGenerator />
        </div>
        <div id="RedeemUcr" className="panel">
          <h2>Redeem Ubiquity Credits</h2>
          <div>
            <UcrRedeem twapInteger={twapInteger} />
            <UcrNftRedeem />
          </div>
        </div>
      </div>
    </WalletConnectionWall>
  );
};

export default PriceStabilization;
