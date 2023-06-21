import { FC } from "react";
import DebtCoupon from "@/components/redeem/debt-coupon";
import useWalletAddress from "@/components/lib/hooks/use-wallet-address";

const DebtCouponPage: FC = (): JSX.Element => {
  const [walletAddress] = useWalletAddress();
  return <div>{walletAddress && <DebtCoupon />}</div>;
};

export default DebtCouponPage;
