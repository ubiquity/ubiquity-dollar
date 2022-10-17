import { BigNumber, Contract, ethers } from "ethers";
import { useState } from "react";
import { SwapWidget } from "@uniswap/widgets";
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
import { SWAP_WIDGET_TOKEN_LIST } from "@/lib/utils";

const UcrRedeem = () => {
  const [walletAddress] = useWalletAddress();
  const signer = useSigner();
  const [balances, refreshBalances] = useBalances();
  const [, doTransaction, doingTransaction] = useTransactionLogger();
  const deployedContracts = useDeployedContracts();
  const managedContracts = useManagerManaged();

  const [inputVal, setInputVal] = useState("0");

  if (!walletAddress || !signer) {
    return <span>Connect wallet</span>;
  }

  if (!managedContracts || !deployedContracts || !balances) {
    return <span>· · ·</span>;
  }

  const redeemUcrForUad = async (amount: BigNumber) => {
    const { debtCouponManager } = deployedContracts;
    await ensureERC20Allowance("uCR -> DebtCouponManager", managedContracts.creditToken as unknown as Contract, amount, signer, debtCouponManager.address);
    await (await debtCouponManager.connect(signer).burnAutoRedeemTokensForDollars(amount)).wait();
    refreshBalances();
  };

  const handleRedeem = () => {
    const amount = extractValidAmount();
    if (amount) {
      doTransaction("Redeeming uCR...", async () => {
        setInputVal("");
        await redeemUcrForUad(amount);
      });
    }
  };

  const extractValidAmount = (val: string = inputVal): null | BigNumber => {
    const amount = safeParseEther(val);
    return amount && amount.gt(BigNumber.from(0)) && amount.lte(balances.ucr) ? amount : null;
  };

  const submitEnabled = !!(extractValidAmount() && !doingTransaction);

  const handleMax = () => {
    const creditTokenValue = ethers.utils.formatEther(balances.ucr);
    setInputVal(parseInt(creditTokenValue).toString());
  };

  return (
    <div>
      <div>
        <PositiveNumberInput placeholder="uCR Amount" value={inputVal} onChange={setInputVal} />
        <span onClick={handleMax}>MAX</span>
      </div>
      <Button onClick={handleRedeem} disabled={!submitEnabled}>
        Redeem uCR for uAD
      </Button>
      <div className="Uniswap">
        <SwapWidget
          defaultInputTokenAddress={"0x5894cFEbFdEdBe61d01F20140f41c5c49AedAe97"}
          tokenList={SWAP_WIDGET_TOKEN_LIST}
        />
      </div>
    </div>
  );
};

export default UcrRedeem;
