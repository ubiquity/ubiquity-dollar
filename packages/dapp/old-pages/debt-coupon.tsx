import DebtCoupon from "old-components/redeem/DebtCoupon";
import useWalletAddress from "old-components/lib/hooks/useWalletAddress";

export default function DebtCouponPage() {
  const [walletAddress] = useWalletAddress();
  return <div>{walletAddress && <DebtCoupon />}</div>;
}
