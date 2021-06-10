import { BigNumber, ethers } from "ethers";
import { Balances, useConnectedContext } from "./context/connected";
import { Dispatch, SetStateAction, useState } from "react";
import Image from "next/image";

const UarRedeem = () => {
  const {
    account,
    debtCouponMgr,
    uAR,
    uAD,
    balances,
    setBalances,
  } = useConnectedContext();
  const [errMsg, setErrMsg] = useState<string>();
  const [isLoading, setIsLoading] = useState<boolean>();
  if (!account || !debtCouponMgr || !uAR || !uAD || !balances) {
    return null;
  }
  if (balances.uar.lte(BigNumber.from(0))) {
    return null;
  }
  const redeem = async (
    amount: BigNumber,
    setBalances: Dispatch<SetStateAction<Balances | undefined>>
  ) => {
    const allowance = await uAR.allowance(
      account.address,
      debtCouponMgr.address
    );
    console.log(
      "allowance",
      ethers.utils.formatEther(allowance),
      "amount",
      ethers.utils.formatEther(amount)
    );
    if (allowance.lt(amount)) {
      // first approve
      const approveTransaction = await uAR.approve(
        debtCouponMgr.address,
        amount
      );

      const approveWaiting = await approveTransaction.wait();
      console.log(
        `approveWaiting gas used with 100 gwei / gas:${ethers.utils.formatEther(
          approveWaiting.gasUsed.mul(ethers.utils.parseUnits("100", "gwei"))
        )}`
      );
    }

    const allowance2 = await uAR.allowance(
      account.address,
      debtCouponMgr.address
    );
    console.log("allowance2", ethers.utils.formatEther(allowance2));
    // redeem uAD
    const redeemWaiting = await debtCouponMgr.burnAutoRedeemTokensForDollars(
      amount
    );
    await redeemWaiting.wait();

    // fetch new uar and uad balance
    const rawUARBalance = await uAR.balanceOf(account.address);
    const rawUADBalance = await uAD.balanceOf(account.address);
    if (balances) {
      setBalances({ ...balances, uad: rawUADBalance, uar: rawUARBalance });
    }
  };
  const handleRedeem = async () => {
    setErrMsg("");
    setIsLoading(true);
    const uarAmount = document.getElementById("uarAmount") as HTMLInputElement;
    const uarAmountValue = uarAmount?.value;
    if (!uarAmountValue) {
      console.log("uarAmountValue", uarAmountValue);
      setErrMsg("amount not valid");
    } else {
      const amount = ethers.utils.parseEther(uarAmountValue);
      if (BigNumber.isBigNumber(amount)) {
        if (amount.gt(BigNumber.from(0))) {
          await redeem(amount, setBalances);
        } else {
          setErrMsg("uAR Amount should be greater than 0");
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
          name="uarAmount"
          id="uarAmount"
          placeholder="uAR amount"
        />
        <button onClick={handleRedeem}>Redeem uAR for uAD</button>
        {isLoading && (
          <Image src="/loadanim.gif" alt="loading" width="64" height="64" />
        )}
        <p className="error">{errMsg}</p>
      </div>
    </>
  );
};

export default UarRedeem;
