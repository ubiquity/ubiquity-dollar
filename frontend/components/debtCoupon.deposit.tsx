import { BigNumber, ethers } from "ethers";
import { Balances, useConnectedContext } from "./context/connected";
import { Dispatch, SetStateAction, useState } from "react";
import Image from "next/image";
import {
  DebtCouponManager__factory,
  ICouponsForDollarsCalculator__factory,
  UbiquityAlgorithmicDollarManager,
  UbiquityAlgorithmicDollar__factory,
} from "../src/types";
import { ADDRESS } from "../pages";

async function _expectedDebtCoupon(
  amount: BigNumber,
  manager: UbiquityAlgorithmicDollarManager | null,
  provider: ethers.providers.Web3Provider | null,
  setExpectedDebtCoupon: Dispatch<SetStateAction<BigNumber | undefined>>
) {
  if (manager && provider) {
    const formulaAdr = await manager.couponCalculatorAddress();
    const SIGNER = provider.getSigner();
    const couponCalculator = ICouponsForDollarsCalculator__factory.connect(
      formulaAdr,
      SIGNER
    );
    const expectedDebtCoupon = await couponCalculator.getCouponAmount(amount);
    console.log("expectedDebtCoupon", expectedDebtCoupon.toString());
    setExpectedDebtCoupon(expectedDebtCoupon);
  }
}

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
  const [expectedDebtCoupon, setExpectedDebtCoupon] = useState<BigNumber>();

  if (!account || !balances) {
    return null;
  }
  if (balances.uad.lte(BigNumber.from(0))) {
    return null;
  }
  const depositDollarForDebtCoupons = async (
    amount: BigNumber,
    setBalances: Dispatch<SetStateAction<Balances | null>>
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
      // depositDollarForDebtCoupons uAD

      const debtCouponMgr = DebtCouponManager__factory.connect(
        ADDRESS.DEBT_COUPON_MANAGER,
        provider.getSigner()
      );
      const depositDollarForDebtCouponsWaiting = await debtCouponMgr.exchangeDollarsForDebtCoupons(
        amount
      );
      await depositDollarForDebtCouponsWaiting.wait();

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
          await depositDollarForDebtCoupons(amount, setBalances);
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

  const handleInputUAD = async () => {
    setErrMsg("");
    setIsLoading(true);
    const missing = `Missing input value for`;
    const bignumberErr = `can't parse BigNumber from`;

    const subject = `uAD amount`;
    const amountEl = document.getElementById("uadAmount") as HTMLInputElement;
    const amountValue = amountEl?.value;
    if (!amountValue) {
      setErrMsg(`${missing} ${subject}`);
      setIsLoading(false);
      return;
    }
    if (BigNumber.isBigNumber(amountValue)) {
      setErrMsg(`${bignumberErr} ${subject}`);
      setIsLoading(false);
      return;
    }
    const amount = ethers.utils.parseEther(amountValue);
    if (!amount.gt(BigNumber.from(0))) {
      setErrMsg(`${subject} should be greater than 0`);
      setIsLoading(false);
      return;
    }

    _expectedDebtCoupon(amount, manager, provider, setExpectedDebtCoupon);
    setIsLoading(false);
  };

  return (
    <>
      <div id="debt-coupon-deposit">
        <input
          type="number"
          name="uadAmount"
          id="uadAmount"
          placeholder="uAD amount"
          onInput={handleInputUAD}
        />
        <button onClick={handleBurn}>Burn uAD for uDEBT</button>
        {isLoading && (
          <Image src="/loadanim.gif" alt="loading" width="64" height="64" />
        )}
        <p>{errMsg}</p>
      </div>
      {expectedDebtCoupon && (
        <p>expected uDEBT {ethers.utils.formatEther(expectedDebtCoupon)}</p>
      )}
    </>
  );
};

export default DebtCouponDeposit;
