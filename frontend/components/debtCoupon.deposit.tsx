import { BigNumber, ethers } from "ethers";
import { Balances, useConnectedContext } from "./context/connected";
import { Dispatch, SetStateAction, useState } from "react";
import Image from "next/image";
import {
  DebtCouponManager__factory,
  UbiquityAlgorithmicDollar__factory,
} from "../src/types";
import { ADDRESS } from "../pages";

const DebtCouponDeposit = () => {
  const {
    account,
    manager,
    provider,
    balances,
    setBalances,
  } = useConnectedContext();
  const [errMsg, setErrMsg] = useState<string>();
  const [isLoading, setIsLoading] = useState<boolean>();
  if (!account || !balances) {
    return null;
  }
  if (balances.uad.lte(BigNumber.from(0))) {
    return null;
  }
  const redeem = async (
    amount: BigNumber,
    setBalances: Dispatch<SetStateAction<Balances | undefined>>
  ) => {
    if (provider && account && manager) {
      const uAD = UbiquityAlgorithmicDollar__factory.connect(
        await manager.dollarTokenAddress(),
        provider.getSigner()
      );
      const allowance = await uAD.allowance(
        account.address,
        ADDRESS.DEBT_COUPON_MANAGER
      );
      console.log(
        "allowance",
        ethers.utils.formatEther(allowance),
        "amount",
        ethers.utils.formatEther(amount)
      );
      if (allowance.lt(amount)) {
        // first approve
        const approveTransaction = await uAD.approve(
          ADDRESS.DEBT_COUPON_MANAGER,
          amount
        );

        const approveWaiting = await approveTransaction.wait();
        console.log(
          `approveWaiting gas used with 100 gwei / gas:${ethers.utils.formatEther(
            approveWaiting.gasUsed.mul(ethers.utils.parseUnits("100", "gwei"))
          )}`
        );
      }

      const allowance2 = await uAD.allowance(
        account.address,
        ADDRESS.DEBT_COUPON_MANAGER
      );
      console.log("allowance2", ethers.utils.formatEther(allowance2));
      // redeem uAD

      const debtCouponMgr = DebtCouponManager__factory.connect(
        ADDRESS.DEBT_COUPON_MANAGER,
        provider.getSigner()
      );
      const redeemWaiting = await debtCouponMgr.exchangeDollarsForDebtCoupons(
        amount
      );
      await redeemWaiting.wait();

      // fetch new uar and uad balance
      setBalances({
        ...balances,
        uad: BigNumber.from(0),
        debtCoupon: BigNumber.from(0),
      });
      /*  const rawUARBalance = await debtCoupon.balanceOf(account.address);
      const rawUADBalance = await uAD.balanceOf(account.address);
      if (balances) {
        setBalances({ ...balances, uad: rawUADBalance, uar: rawUARBalance });
      } */
    }
  };
  const handleBurn = async () => {
    setErrMsg("");
    setIsLoading(true);
    const uadAmount = document.getElementById("uadAmount") as HTMLInputElement;
    const uadAmountValue = uadAmount?.value;
    if (!uadAmountValue) {
      console.log("uadAmountValue", uadAmountValue);
      setErrMsg("amount not valid");
    } else {
      const amount = ethers.utils.parseEther(uadAmountValue);
      if (BigNumber.isBigNumber(amount)) {
        if (amount.gt(BigNumber.from(0))) {
          await redeem(amount, setBalances);
        } else {
          setErrMsg("uAD Amount should be greater than 0");
        }
      } else {
        setErrMsg("amount not valid");
        setIsLoading(false);
        return;
      }
    }
    setIsLoading(false);
  };

  return (
    <>
      <div className="row">
        <input
          type="number"
          name="uadAmount"
          id="uadAmount"
          placeholder="uAD amount"
        />
        <button onClick={handleBurn}>Burn uAD for uDebt</button>
        {isLoading && (
          <Image src="/loadanim.gif" alt="loading" width="64" height="64" />
        )}
        <p className="error">{errMsg}</p>
      </div>
    </>
  );
};

export default DebtCouponDeposit;
