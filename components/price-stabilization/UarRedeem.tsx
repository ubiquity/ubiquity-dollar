import { BigNumber } from "ethers";
import { useState } from "react";

import { ensureERC20Allowance } from "@/lib/contracts-shortcuts";
import { safeParseEther } from "@/lib/utils";
import { PositiveNumberInput } from "@/ui";
import { useBalances, useDeployedContracts, useManagerManaged, useSigner, useTransactionLogger, useWalletAddress } from "@/lib/hooks";

const UarRedeem = () => {
  const [walletAddress] = useWalletAddress();
  const signer = useSigner();
  const [balances, refreshBalances] = useBalances();
  const [, doTransaction, doingTransaction] = useTransactionLogger();
  const deployedContracts = useDeployedContracts();
  const managedContracts = useManagerManaged();

  const [inputVal, setInputVal] = useState("");

  if (!walletAddress || !signer) {
    return <span>Connnect wallet</span>;
  }

  if (!managedContracts || !deployedContracts || !balances) {
    return <span>Loading...</span>;
  }

  const redeemUarForUad = async (amount: BigNumber) => {
    const { debtCouponManager } = deployedContracts;
    await ensureERC20Allowance("uAR -> DebtCouponManager", managedContracts.uar, amount, signer, debtCouponManager.address);
    await (await debtCouponManager.connect(signer).burnAutoRedeemTokensForDollars(amount)).wait();
    refreshBalances();
  };

  const handleRedeem = () => {
    const amount = extractValidAmount();
    if (amount) {
      doTransaction("Redeeming uAR...", async () => {
        setInputVal("");
        await redeemUarForUad(amount);
      });
    }
  };

  const extractValidAmount = (val: string = inputVal): null | BigNumber => {
    const amount = safeParseEther(val);
    return amount && amount.gt(BigNumber.from(0)) && amount.lte(balances.uar) ? amount : null;
  };

  const submitEnabled = !!(extractValidAmount() && !doingTransaction);

  return (
    <>
      <div className="flex flex-col">
        <PositiveNumberInput placeholder="uAR Amount" value={inputVal} onChange={setInputVal} />
        <button onClick={handleRedeem} disabled={!submitEnabled}>
          Redeem uAR for uAD
        </button>
      </div>
    </>
  );
};

export default UarRedeem;
