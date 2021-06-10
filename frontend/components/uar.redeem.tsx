import { BigNumber, ethers } from "ethers";
import { useConnectedContext } from "./context/connected";
import { useState } from "react";

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

  if (!account || !debtCouponMgr || !uAR || !uAD || !balances) {
    return null;
  }
  if (balances.uar.lte(BigNumber.from(0))) {
    return null;
  }
  const handleRedeem = async () => {
    setErrMsg("");
    const uarAmount = document.getElementById("uarAmount") as HTMLInputElement;
    const uarAmountValue = uarAmount?.value;
    if (!uarAmountValue) {
      setErrMsg("uAR Amount should be greater than 0");
    }

    // first approve
    const approveTransaction = await uAR.approve(
      debtCouponMgr.address,
      uarAmountValue
    );

    const approveWaiting = await approveTransaction.wait();
    console.log(
      `approveWaiting gas used with 100 gwei / gas:${ethers.utils.formatEther(
        approveWaiting.gasUsed.mul(ethers.utils.parseUnits("100", "gwei"))
      )}`
    );
    const allowance2 = await uAR.allowance(
      account.address,
      debtCouponMgr.address
    );
    console.log("allowance2", ethers.utils.formatEther(allowance2));
    // redeem uAD
    const redeemWaiting = await debtCouponMgr.burnAutoRedeemTokensForDollars(
      uarAmountValue
    );
    await redeemWaiting.wait();

    // fetch new uar and uad balance

    const rawUARBalance = await uAR.balanceOf(account.address);
    const rawUADBalance = await uAD.balanceOf(account.address);
    if (balances) {
      balances.uar = rawUARBalance;
      balances.uad = rawUADBalance;
      setBalances(balances);
    }
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
        <p className="error">{errMsg}</p>
      </div>
    </>
  );
};

export default UarRedeem;
