import DebtCoupon from "@/components/redeem/DebtCoupon";
import useWalletAddress from "@/components/lib/hooks/useWalletAddress";

export default function DebtCouponPage() {
  const [walletAddress] = useWalletAddress();
  return <div>{walletAddress && <DebtCoupon />}</div>;
}
