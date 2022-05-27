import { FC } from "react";
import DebtCoupon from "@/components/redeem/DebtCoupon";
import { useWalletAddress } from "@/components/lib/hooks";

const DebtCouponPage: FC = (): JSX.Element => {
  const [walletAddress] = useWalletAddress();
  return <div>{walletAddress && <DebtCoupon />}</div>;
};

export default DebtCouponPage;
