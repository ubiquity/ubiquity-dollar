import { BigNumber } from "ethers";
import { useState } from "react";

import { ERC20 } from "@/dollar-types";
import { ensureERC20Allowance } from "@/lib/contracts-shortcuts";
import { safeParseEther } from "@/lib/utils";
import useDeployedContracts from "../lib/hooks/contracts/useDeployedContracts";
import useManagerManaged from "../lib/hooks/contracts/useManagerManaged";
import useBalances from "../lib/hooks/useBalances";
import useSigner from "../lib/hooks/useSigner";
import useTransactionLogger from "../lib/hooks/useTransactionLogger";
import useWalletAddress from "../lib/hooks/useWalletAddress";
import Button from "../ui/Button";
import PositiveNumberInput from "../ui/PositiveNumberInput";

const UarRedeem = () => {
  const [walletAddress] = useWalletAddress();
  const signer = useSigner();
  const [balances, refreshBalances] = useBalances();
  const [, doTransaction, doingTransaction] = useTransactionLogger();
  const deployedContracts = useDeployedContracts();
  const managedContracts = useManagerManaged();

  const [inputVal, setInputVal] = useState("");

  if (!walletAddress || !signer) {
    return <span>Connect wallet</span>;
  }

  if (!managedContracts || !deployedContracts || !balances) {
    return <span>· · ·</span>;
  }

  const redeemUarForUad = async (amount: BigNumber) => {
    const { debtCouponManager } = deployedContracts;
    await ensureERC20Allowance("uCR -> DebtCouponManager", managedContracts.uar as unknown as ERC20, amount, signer, debtCouponManager.address);
    await (await debtCouponManager.connect(signer).burnAutoRedeemTokensForDollars(amount)).wait();
    refreshBalances();
  };

  const handleRedeem = () => {
    const amount = extractValidAmount();
    if (amount) {
      doTransaction("Redeeming uCR...", async () => {
        setInputVal("");
        await redeemUarForUad(amount);
      });
    }
  };

  const extractValidAmount = (val: string = inputVal): null | BigNumber => {
    const amount = safeParseEther(val);
    return amount && amount.gt(BigNumber.from(0)) && amount.lte(balances.ucr) ? amount : null;
  };

  const submitEnabled = !!(extractValidAmount() && !doingTransaction);

  return (
    <div>
      <PositiveNumberInput placeholder="uCR Amount" value={inputVal} onChange={setInputVal} />
      <Button onClick={handleRedeem} disabled={!submitEnabled}>
        Redeem uCR for uAD
      </Button>
    </div>
  );
};

export default UarRedeem;
