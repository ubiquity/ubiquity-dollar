import { BigNumber, ethers } from "ethers";
import { Dispatch, SetStateAction, useEffect, useState } from "react";
import { Dropdown } from "react-dropdown-now";
import { ADDRESS } from "../pages";
import { DebtCouponManager__factory, DebtCoupon__factory, UbiquityAlgorithmicDollarManager } from "../contracts/artifacts/types";
import { useConnectedContext } from "./context/connected";
import { Balances } from "./common/contracts-shortcuts";

const _getDebtIds = async (
  account: string,
  manager: UbiquityAlgorithmicDollarManager | null,
  provider: ethers.providers.Web3Provider | null,
  debtIds: BigNumber[] | undefined,
  setDebtIds: Dispatch<SetStateAction<BigNumber[] | undefined>>
) => {
  if (manager && provider) {
    const debtCoupon = DebtCoupon__factory.connect(await manager.debtCouponAddress(), provider.getSigner());
    const ids = await debtCoupon.holderTokens(account);
    if (debtIds === undefined || debtIds.length !== ids.length || debtIds.map((cur, i) => ids[i].eq(cur)).filter((p) => p === false).length > 0)
      setDebtIds(ids);
  }
};

const UDEBT_REDEEM_TRANSACTION = "UDEBT_REDEEM_TRANSACTION";

const DebtCouponRedeem = () => {
  const { account, manager, provider, balances, setBalances, updateActiveTransaction } = useConnectedContext();
  const [debtIds, setDebtIds] = useState<BigNumber[]>();
  useEffect(() => {
    console.log("DebtCouponRedeem  ");
    _getDebtIds(account ? account.address : "", manager, provider, debtIds, setDebtIds);
  });

  const [errMsg, setErrMsg] = useState<string>();
  const [debtId, setDebtId] = useState<string>();

  if (!account || !balances) {
    return null;
  }
  if (balances.uad.lte(BigNumber.from(0))) {
    return null;
  }
  const redeemDebtForDollar = async (debtId: string | undefined, amount: BigNumber, setBalances: Dispatch<SetStateAction<Balances | null>>) => {
    console.log("debtId", debtId);
    if (provider && account && manager && debtId) {
      const debtCoupon = DebtCoupon__factory.connect(await manager.debtCouponAddress(), provider.getSigner());
      const isAllowed = await debtCoupon.isApprovedForAll(account.address, ADDRESS.DEBT_COUPON_MANAGER);
      console.log("isAllowed", isAllowed);
      if (!isAllowed) {
        // first approve
        const approveTransaction = await debtCoupon.setApprovalForAll(ADDRESS.DEBT_COUPON_MANAGER, true);

        const approveWaiting = await approveTransaction.wait();
        console.log(
          `approveWaiting gas used with 100 gwei / gas:${ethers.utils.formatEther(approveWaiting.gasUsed.mul(ethers.utils.parseUnits("100", "gwei")))}`
        );
      }

      const isAllowed2 = await debtCoupon.isApprovedForAll(account.address, ADDRESS.DEBT_COUPON_MANAGER);
      console.log("isAllowed2", isAllowed2);

      const debtCouponMgr = DebtCouponManager__factory.connect(ADDRESS.DEBT_COUPON_MANAGER, provider.getSigner());
      const redeemCouponsWaiting = await debtCouponMgr.redeemCoupons(BigNumber.from(debtId), amount);
      await redeemCouponsWaiting.wait();

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

  const handleRedeem = async () => {
    setErrMsg("");
    const title = "Redeeming uDEBT...";
    updateActiveTransaction({ id: UDEBT_REDEEM_TRANSACTION, title, active: true });
    const udebtAmount = document.getElementById("udebtAmount") as HTMLInputElement;
    const udebtAmountValue = udebtAmount?.value;
    if (!udebtAmountValue) {
      console.log("udebtAmountValue", udebtAmountValue);
      setErrMsg("amount not valid");
    } else {
      const amount = ethers.utils.parseEther(udebtAmountValue);
      if (BigNumber.isBigNumber(amount)) {
        if (amount.gt(BigNumber.from(0))) {
          await redeemDebtForDollar(debtId, amount, setBalances);
        } else {
          setErrMsg("uDEBT Amount should be greater than 0");
        }
      } else {
        setErrMsg("amount not valid");
        updateActiveTransaction({ id: UDEBT_REDEEM_TRANSACTION, active: false });
        return;
      }
    }
    updateActiveTransaction({ id: UDEBT_REDEEM_TRANSACTION, active: false });
  };

  return (
    <>
      <div id="debt-coupon-redeem">
        <Dropdown
          arrowClosed={<span className="arrow-closed" />}
          arrowOpen={<span className="arrow-open" />}
          placeholder="Select an option"
          className="dropdown"
          options={debtIds?.map((i) => i.toString()) ?? []}
          onChange={(value) => setDebtId(value.value as string)}
        />

        <input type="number" name="udebtAmount" id="udebtAmount" placeholder="uDEBT Amount" />
        <button onClick={handleRedeem}>Redeem uDEBT for uAD</button>
        <p>{errMsg}</p>
      </div>
    </>
  );
};

export default DebtCouponRedeem;
