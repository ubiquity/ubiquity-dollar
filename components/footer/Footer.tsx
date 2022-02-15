import { useConnectedContext } from "../context/connected";
import CurveBalance from "../curve.balance";
import CurveLPBalance from "../curveLP.balance";
import DebtCouponBalance from "../debtCoupon.balance";
import UadBalance from "../uad.balance";
import UarBalance from "../uar.balance";
import UbqBalance from "../ubq.balance";

export default function Header() {
  const { balances } = useConnectedContext();

  if (!balances) {
    return null;
  }

  return (
    <>
      <div id="inventory-top">
        <div>
          <div>
            <aside>My Ubiquity Inventory</aside>
            <figure></figure>
          </div>
          <UbqBalance />
          <UadBalance />
          <UarBalance />
          <DebtCouponBalance />
          <CurveBalance />
          <CurveLPBalance />
        </div>
      </div>
    </>
  );
}
