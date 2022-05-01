import { FC } from "react";
import { useConnectedContext } from "../components/context/connected";
import DebtCoupon from "../components/DebtCoupon";

const DebtCouponPage: FC = (): JSX.Element => {
  const context = useConnectedContext();
  const { account } = context;
  return <div>{account && <DebtCoupon />}</div>;
};

export default DebtCouponPage;
