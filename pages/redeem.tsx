import { FC, useState } from "react";
import { ethers } from "ethers";

import MigrateButton from "@/components/redeem/MigrateButton";
import DollarPrice from "@/components/redeem/DollarPrice";
import UarRedeem from "@/components/redeem/UarRedeem";
import DebtCouponDeposit from "@/components/redeem/DebtCouponDeposit";
import DebtCouponRedeem from "@/components/redeem/DebtCouponRedeem";
import useManagerManaged from "@/components/lib/hooks/contracts/useManagerManaged";
import useEffectAsync from "@/components/lib/hooks/useEffectAsync";
import useWalletAddress from "@/components/lib/hooks/useWalletAddress";
import DisabledBlurredMessage from "@/components/ui/DisabledBlurredMessage";
import WalletNotConnected from "@/components/ui/WalletNotConnected";

const PriceStabilization: FC = (): JSX.Element => {
  const [twapPrice, setTwapPrice] = useState<ethers.BigNumber | null>(null);
  const [walletAddress] = useWalletAddress();
  const managedContracts = useManagerManaged();

  useEffectAsync(async () => {
    if (managedContracts) {
      setTwapPrice(await managedContracts.twapOracle.consult(managedContracts.uad.address));
    }
  }, [managedContracts]);

  const twapGt1 = twapPrice?.gte(ethers.utils.parseEther("1")) ?? false;

  return walletAddress ? (
    <>
      <h2>uAD Price</h2>
      <DollarPrice />
      <MigrateButton />
      <div>
        <h2>Mint Ubiquity Credits</h2>
        <aside>When TWAP &lt;1</aside>
        <DisabledBlurredMessage disabled={twapGt1} content="Disabled while TWAP > 1">
          <DebtCouponDeposit />
          {/* <UarDeposit /> */}
        </DisabledBlurredMessage>
        <h2>Redeem Ubiquity Credits</h2>
        <aside>When TWAP &gt; 1</aside>
        <DisabledBlurredMessage disabled={!twapGt1} content="Disabled while TWAP < 1">
          <div>
            <UarRedeem />
            <DebtCouponRedeem />
          </div>
        </DisabledBlurredMessage>
      </div>
    </>
  ) : (
    WalletNotConnected
  );
};

export default PriceStabilization;
