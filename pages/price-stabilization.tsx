import { FC, useState } from "react";
import { ethers } from "ethers";

import { DisabledBlurredMessage, Container, Title, SubTitle, WalletNotConnected } from "@/ui";

import MigrateButton from "@/components/price-stabilization/MigrateButton";
import DollarPrice from "@/components/price-stabilization/DollarPrice";
import UarRedeem from "@/components/price-stabilization/UarRedeem";
import DebtCouponDeposit from "@/components/price-stabilization/DebtCouponDeposit";
import DebtCouponRedeem from "@/components/price-stabilization/DebtCouponRedeem";
import { useManagerManaged, useWalletAddress, useEffectAsync } from "@/components/lib/hooks";

const PriceStabilization: FC = (): JSX.Element => {
  const [twapPrice, setTwapPrice] = useState<ethers.BigNumber | null>(null);
  const walletAddress = useWalletAddress();
  const managedContracts = useManagerManaged();

  useEffectAsync(async () => {
    if (managedContracts) {
      setTwapPrice(await managedContracts.twapOracle.consult(managedContracts.uad.address));
    }
  }, [managedContracts]);

  const twapGt1 = twapPrice?.gte(ethers.utils.parseEther("1")) ?? false;

  return walletAddress ? (
    <>
      <Container>
        <Title text="uAD Price" />
        <DollarPrice />
        <MigrateButton />
      </Container>
      <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
        <Container className="w-full">
          <Title text="Mint Credit Coupons" />
          <SubTitle text="When TWAP < 1" />
          <DisabledBlurredMessage disabled={twapGt1} content="Disabled while TWAP > 1">
            <DebtCouponDeposit />
            {/* <UarDeposit /> */}
          </DisabledBlurredMessage>
        </Container>
        <Container className="w-full">
          <Title text="Redeem Credit Coupons" />
          <SubTitle text="When TWAP > 1" />
          <DisabledBlurredMessage disabled={!twapGt1} content="Disabled while TWAP < 1">
            <UarRedeem />
            <DebtCouponRedeem />
          </DisabledBlurredMessage>
        </Container>
      </div>
    </>
  ) : (
    WalletNotConnected
  );
};

export default PriceStabilization;
