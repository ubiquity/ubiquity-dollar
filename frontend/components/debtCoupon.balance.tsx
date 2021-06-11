import { ethers, BigNumber } from "ethers";
import { UbiquityAlgorithmicDollarManager } from "../src/types/UbiquityAlgorithmicDollarManager";
import { Balances, useConnectedContext } from "./context/connected";
import { Dispatch, SetStateAction, useEffect, useState } from "react";
import {
  BondingShare,
  BondingShare__factory,
  DebtCoupon,
  DebtCoupon__factory,
} from "../src/types";

async function calculateDebtCouponBalance(
  addr: string,
  debtCoupon: DebtCoupon
) {
  //console.log({ addr });
  const ids = await debtCoupon.holderTokens(addr);

  let bondingSharesBalance = BigNumber.from("0");
  if (ids && ids.length > 0) {
    bondingSharesBalance = await debtCoupon.balanceOf(addr, ids[0]);
  }

  // console.log({ ids, bondingSharesBalance });

  //
  let balance = BigNumber.from("0");
  if (ids.length > 1) {
    /*  console.log(` 
    bondingShares ids 1:${ids[1]} balance:${await bondingShare.balanceOf(
      addr,
      ids[1]
    )}
 
    `); */
    const balanceOfs = ids.map((id) => {
      return bondingShare.balanceOf(addr, id);
    });
    const balances = Promise.all(balanceOfs);
    balance = (await balances).reduce((prev, cur) => {
      return prev.add(cur);
    });
  } else {
    balance = bondingSharesBalance;
  }

  return balance;
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
        if (!balances.bondingShares.eq(rawBalance))
          setBalances({ ...balances, bondingShares: rawBalance });
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
      <div className="row">
        <button onClick={handleBalance}>Get DebtCoupon</button>
        <p className="value">
          {balances ? ethers.utils.formatEther(balances.debtCoupon) : "0.0"}{" "}
          DebtCoupon
        </p>
      </div>
    </>
  );
};

export default DebtCouponBalance;
