import { FC } from "react";
import { ethers } from "ethers";

import { DisabledBlurredMessage, Container, Title, SubTitle, WalletNotConnected } from "@/ui";
import { useConnectedContext } from "@/lib/connected";

import BondingMigrate from "@/components/price-stabilization/bonding.migrate";
import DollarPrice from "@/components/price-stabilization/DollarPrice";
import UarRedeem from "@/components/price-stabilization/uar.redeem";
import DebtCouponDeposit from "@/components/price-stabilization/debtCoupon.deposit";
import DebtCouponRedeem from "@/components/price-stabilization/debtCoupon.redeem";

const PriceStabilization: FC = (): JSX.Element => {
  const context = useConnectedContext();
  const { account, balances, twapPrice } = context;

  const twapGt1 = twapPrice?.gte(ethers.utils.parseEther("1")) ?? false;

  return account ? (
    <>
      <Container>
        <Title text="uAD Price" />
        <DollarPrice />
        <BondingMigrate />
      </Container>
      <Container>
        <Title text="Mint Debt Coupons" />
        <SubTitle text="When TWAP < 1" />
        <DisabledBlurredMessage disabled={twapGt1} content="Disabled while TWAP > 1">
          <DebtCouponDeposit />
        </DisabledBlurredMessage>
      </Container>
      <Container>
        <Title text="Redeem Debt Coupons" />
        <SubTitle text="When TWAP > 1" />
        <DisabledBlurredMessage disabled={!twapGt1} content="Disabled while TWAP < 1">
          <UarRedeem />
          <DebtCouponRedeem />
        </DisabledBlurredMessage>
      </Container>
    </>
  ) : (
    WalletNotConnected
  );
};

export default PriceStabilization;
