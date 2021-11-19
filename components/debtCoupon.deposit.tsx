import { BigNumber, ethers } from "ethers";
import { Dispatch, SetStateAction, useState } from "react";
import { ADDRESS } from "../pages";
import {
  DebtCouponManager__factory,
  ICouponsForDollarsCalculator__factory,
  UbiquityAlgorithmicDollarManager,
  UbiquityAlgorithmicDollar__factory,
} from "../contracts/artifacts/types";
import { useConnectedContext } from "./context/connected";
import { Balances } from "./common/contracts-shortcuts";

async function _expectedDebtCoupon(
  amount: BigNumber,
  manager: UbiquityAlgorithmicDollarManager | null,
  provider: ethers.providers.Web3Provider | null,
  setExpectedDebtCoupon: Dispatch<SetStateAction<BigNumber | undefined>>
) {
  if (manager && provider) {
    const formulaAdr = await manager.couponCalculatorAddress();
    const SIGNER = provider.getSigner();
    const couponCalculator = ICouponsForDollarsCalculator__factory.connect(formulaAdr, SIGNER);
    const expectedDebtCoupon = await couponCalculator.getCouponAmount(amount);
    console.log("expectedDebtCoupon", expectedDebtCoupon.toString());
    setExpectedDebtCoupon(expectedDebtCoupon);
  }
}

const DEBT_COUPON_DEPOSIT_TRANSACTION = "DEBT_COUPON_DEPOSIT_TRANSACTION";

const DebtCouponDeposit = () => {
  const { account, manager, provider, balances, setBalances, updateActiveTransaction } = useConnectedContext();
  const [errMsg, setErrMsg] = useState<string>();
  const [expectedDebtCoupon, setExpectedDebtCoupon] = useState<BigNumber>();

  if (!account || !balances) {
    return null;
  }
  if (balances.uad.lte(BigNumber.from(0))) {
    return null;
  }
  const depositDollarForDebtCoupons = async (amount: BigNumber, setBalances: Dispatch<SetStateAction<Balances | null>>) => {
    if (provider && account && manager) {
      const uAD = UbiquityAlgorithmicDollar__factory.connect(await manager.dollarTokenAddress(), provider.getSigner());
      const allowance = await uAD.allowance(account.address, ADDRESS.DEBT_COUPON_MANAGER);
      console.log("allowance", ethers.utils.formatEther(allowance), "amount", ethers.utils.formatEther(amount));
      if (allowance.lt(amount)) {
        // first approve
        const approveTransaction = await uAD.approve(ADDRESS.DEBT_COUPON_MANAGER, amount);

        const approveWaiting = await approveTransaction.wait();
        console.log(
          `approveWaiting gas used with 100 gwei / gas:${ethers.utils.formatEther(approveWaiting.gasUsed.mul(ethers.utils.parseUnits("100", "gwei")))}`
        );
      }

      const allowance2 = await uAD.allowance(account.address, ADDRESS.DEBT_COUPON_MANAGER);
      console.log("allowance2", ethers.utils.formatEther(allowance2));
      // depositDollarForDebtCoupons uAD

      const debtCouponMgr = DebtCouponManager__factory.connect(ADDRESS.DEBT_COUPON_MANAGER, provider.getSigner());
      const depositDollarForDebtCouponsWaiting = await debtCouponMgr.exchangeDollarsForDebtCoupons(amount);
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
    const title = "Burning uAD...";
    updateActiveTransaction({ id: DEBT_COUPON_DEPOSIT_TRANSACTION, title, active: true });
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
        updateActiveTransaction({ id: DEBT_COUPON_DEPOSIT_TRANSACTION, active: false });
        return;
      }
    }
    updateActiveTransaction({ id: DEBT_COUPON_DEPOSIT_TRANSACTION, active: false });
  };

  const handleInputUAD = async () => {
    setErrMsg("");
    const title = "Input uAD...";
    updateActiveTransaction({ id: DEBT_COUPON_DEPOSIT_TRANSACTION, title, active: true });
    const missing = `Missing input value for`;
    const bignumberErr = `can't parse BigNumber from`;

    const subject = `uAD amount`;
    const amountEl = document.getElementById("uadAmount") as HTMLInputElement;
    const amountValue = amountEl?.value;
    if (!amountValue) {
      setErrMsg(`${missing} ${subject}`);
      updateActiveTransaction({ id: DEBT_COUPON_DEPOSIT_TRANSACTION, active: false });
      return;
    }
    if (BigNumber.isBigNumber(amountValue)) {
      setErrMsg(`${bignumberErr} ${subject}`);
      updateActiveTransaction({ id: DEBT_COUPON_DEPOSIT_TRANSACTION, active: false });
      return;
    }
    const amount = ethers.utils.parseEther(amountValue);
    if (!amount.gt(BigNumber.from(0))) {
      setErrMsg(`${subject} should be greater than 0`);
      updateActiveTransaction({ id: DEBT_COUPON_DEPOSIT_TRANSACTION, active: false });
      return;
    }

    _expectedDebtCoupon(amount, manager, provider, setExpectedDebtCoupon);
    updateActiveTransaction({ id: DEBT_COUPON_DEPOSIT_TRANSACTION, active: false });
  };

  return (
    <>
      <div id="debt-coupon-deposit">
        <input type="number" name="uadAmount" id="uadAmount" placeholder="uAD Amount" onInput={handleInputUAD} />
        <button onClick={handleBurn}>Redeem uAD for uDEBT</button>
        <p>{errMsg}</p>
      </div>
      {expectedDebtCoupon && <p>expected uDEBT {ethers.utils.formatEther(expectedDebtCoupon)}</p>}
    </>
  );
};

export default DebtCouponDeposit;
