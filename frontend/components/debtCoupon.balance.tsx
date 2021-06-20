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
  manager: UbiquityAlgorithmicDollarManager | undefined,
  provider: ethers.providers.Web3Provider | undefined,
  balances: Balances | undefined,
  setBalances: Dispatch<SetStateAction<Balances | undefined>>
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

  const handleBalance = async () => {
    _debtCouponBalance(
      account ? account.address : "",
      manager,
      provider,
      balances,
      setBalances
    );
  };
  return (
    <>
      <div>
        <p>
          {balances ? ethers.utils.formatEther(balances.debtCoupon) : "0.0"}{" "}
          uDebt
        </p>
        <button onClick={handleBalance}>Get uDebt</button>
      </div>
    </>
  );
};

export default DebtCouponBalance;
