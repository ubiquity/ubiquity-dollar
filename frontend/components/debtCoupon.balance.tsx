import { ethers, BigNumber } from "ethers";
import { UbiquityAlgorithmicDollarManager } from "../src/types/UbiquityAlgorithmicDollarManager";
import { Balances, useConnectedContext } from "./context/connected";
import { Dispatch, SetStateAction, useEffect } from "react";
import { DebtCoupon, DebtCoupon__factory } from "../src/types";

async function calculateDebtCouponBalance(
  addr: string,
  debtCoupon: DebtCoupon
) {
  const ids = await debtCoupon.holderTokens(addr);
  const balanceOfs = ids.map((id) => {
    return debtCoupon.balanceOf(addr, id);
  });
  const balances = await Promise.all(balanceOfs);
  let fullBalance = BigNumber.from(0);
  if (balances.length > 0) {
    fullBalance = balances.reduce((prev, cur) => {
      return prev.add(cur);
    });
  }
  return fullBalance;
}
async function _debtCouponBalance(
  account: string,
  manager: UbiquityAlgorithmicDollarManager | null,
  provider: ethers.providers.Web3Provider | null,
  balances: Balances | null,
  setBalances: Dispatch<SetStateAction<Balances | null>>
) {
  if (manager && provider) {
    const debtCoupon = DebtCoupon__factory.connect(
      await manager.debtCouponAddress(),
      provider
    );

    if (debtCoupon) {
      const rawBalance = await calculateDebtCouponBalance(account, debtCoupon);
      if (balances) {
        if (!balances.debtCoupon.eq(rawBalance))
          setBalances({ ...balances, debtCoupon: rawBalance });
      }
    }
  }
}

const DebtCouponBalance = () => {
  const {
    account,
    manager,
    provider,
    balances,
    setBalances,
  } = useConnectedContext();

  useEffect(() => {
    _debtCouponBalance(
      account ? account.address : "",
      manager,
      provider,
      balances,
      setBalances
    );
  }, [balances]);

  if (!account) {
    return null;
  }

  return (
    <>
      <div id="debt-coupon-balance">
        <div>
          <span>
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 75 85.45">
              <path d="M75 31.81v30.41a3.72 3.72 0 0 1-1.68 3.11l-.18.12L39.36 85a3.75 3.75 0 0 1-3.52.11l-.2-.11L1.86 65.45a3.73 3.73 0 0 1-1.85-3V44.66L11 51l.35.2a31.49 31.49 0 0 0 30.75-.09l.44-.26zM68 17l5.12 3A3.72 3.72 0 0 1 75 23v.13L38.76 44.34l-.33.19a24 24 0 0 1-23.31.15l-.4-.22L0 36V25.76l11 6.32.35.2a31.49 31.49 0 0 0 30.75-.09l.45-.26zM37.5 0a3.75 3.75 0 0 1 1.64.38l.22.12 21.19 12.23L38.8 25.46l-.33.19a24 24 0 0 1-23.31.15l-.4-.22-11.32-6.49L35.64.5a3.64 3.64 0 0 1 1.62-.5z" />
            </svg>
          </span>
          <span>
            {balances
              ? `${parseInt(ethers.utils.formatEther(balances.debtCoupon))}`
              : "0"}{" "}
            uDEBT
          </span>
        </div>
      </div>
    </>
  );
};

export default DebtCouponBalance;
