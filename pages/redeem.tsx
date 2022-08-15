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
      <DollarPrice />
      <MigrateButton />
      <div id="MintUcr">
        <h2>Mint Ubiquity Credits</h2>
        <aside>When TWAP is below peg</aside>
        <DisabledBlurredMessage disabled={twapGt1} content="Disabled when TWAP is above peg">
          <DebtCouponDeposit />
          {/* <UarDeposit /> */}
        </DisabledBlurredMessage>
      </div>
      <div id="RedeemUcr">
        <h2>Redeem Ubiquity Credits</h2>
        <aside>When TWAP is above peg</aside>
        <DisabledBlurredMessage disabled={!twapGt1} content="Disabled when TWAP is below peg">
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
