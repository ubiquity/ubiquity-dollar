import { FC } from "react";
import { useConnectedContext } from "@/lib/connected";
import DebtCoupon from "@/components/price-stabilization/DebtCoupon";

const DebtCouponPage: FC = (): JSX.Element => {
  const context = useConnectedContext();
  const { account } = context;
  return <div>{account && <DebtCoupon />}</div>;
};

export default DebtCouponPage;
