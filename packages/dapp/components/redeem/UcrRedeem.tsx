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
import Button from "../ui/Button";
import PositiveNumberInput from "../ui/PositiveNumberInput";
import useRouter from "../lib/hooks/useRouter";
import useTrade from "../lib/hooks/useTrade";
import { USDC_ADDRESS, SWAP_WIDGET_TOKEN_LIST, V3_ROUTER_ADDRESS } from "@/lib/utils";
import { getUniswapV3RouterContract } from "../utils/contracts";
import useWeb3 from "@/components/lib/hooks/useWeb3";

const UcrRedeem = ({ twapInteger }: { twapInteger: number }) => {
  const [{ provider, walletAddress }] = useWeb3();
  const signer = useSigner();
  const [balances, refreshBalances] = useBalances();
  const [, doTransaction, doingTransaction] = useTransactionLogger();
  const deployedContracts = useDeployedContracts();
  const managedContracts = useManagerManaged();

  const [inputVal, setInputVal] = useState("0");
  const [selectedRedeemToken, setSelectedRedeemToken] = useState("uAD");
  const [quoteAmount, lastQuoteAmount] = useRouter(selectedRedeemToken, inputVal);
  const currentlyAbovePeg = twapInteger > 1;

  if (!walletAddress || !signer) {
    return <span>Connect wallet</span>;
  }

  if (!managedContracts || !deployedContracts || !balances) {
    return <span>· · ·</span>;
  }

  const redeemUcr = async (amount: BigNumber) => {
    const { debtCouponManager } = deployedContracts;
    await ensureERC20Allowance("uCR -> DebtCouponManager", managedContracts.creditToken as unknown as Contract, amount, signer, debtCouponManager.address);
    await (await debtCouponManager.connect(signer).burnAutoRedeemTokensForDollars(amount)).wait();
    refreshBalances();
    if (provider && quoteAmount && selectedRedeemToken !== "uAD") {
      const routerContract = getUniswapV3RouterContract(V3_ROUTER_ADDRESS, provider);
      await (await routerContract.connect(signer).approveMax(quoteAmount, managedContracts.dollarToken)).wait();
      await useTrade(selectedRedeemToken, quoteAmount);
      refreshBalances();
    }
  };

  const handleRedeem = () => {
    const amount = extractValidAmount();
    if (amount) {
      doTransaction("Redeeming uCR...", async () => {
        setInputVal("");
        await redeemUcr(amount);
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

  function onChangeValue(e: React.ChangeEvent<HTMLInputElement>) {
    setSelectedRedeemToken(e.target.value);
  }

  return (
    <div>
      {!currentlyAbovePeg ? (
        <div>
          <h4>TWAP is above peg</h4>
          <div>uCR-&gt;uAD-&gt;USDC/DAI/USDT</div>
          <div onChange={onChangeValue}>
            <p>Please select a token to redeem for:</p>
            <input type="radio" id="tokenChoice1" name="redeemToken" value="uAD" checked={selectedRedeemToken === "uAD"} readOnly />
            <label htmlFor="tokenChoice1">uAD</label>

            <input type="radio" id="tokenChoice2" name="redeemToken" value="USDC" checked={selectedRedeemToken === "USDC"} readOnly />
            <label htmlFor="tokenChoice2">USDC</label>

            <input type="radio" id="tokenChoice3" name="redeemToken" value="DAI" checked={selectedRedeemToken === "DAI"} readOnly />
            <label htmlFor="tokenChoice3">DAI</label>

            <input type="radio" id="tokenChoice4" name="redeemToken" value="USDT" checked={selectedRedeemToken === "USDT"} readOnly />
            <label htmlFor="tokenChoice4">USDT</label>
          </div>
          <div>
            <PositiveNumberInput placeholder="uCR Amount" value={inputVal} onChange={setInputVal} />
            <span onClick={handleMax}>MAX</span>
          </div>
          {inputVal && quoteAmount && !lastQuoteAmount && (
            <div>
              {inputVal} uCR -&gt; {quoteAmount} uAD.
            </div>
          )}
          {inputVal && quoteAmount && lastQuoteAmount && (
            <div>
              {inputVal} uCR -&gt; {quoteAmount} uAD -&gt; {lastQuoteAmount}.
            </div>
          )}
          <Button onClick={handleRedeem} disabled={!submitEnabled}>
            Redeem uCR for {selectedRedeemToken}
          </Button>
        </div>
      ) : (
        <div className="Uniswap">
          <h4>TWAP is below peg</h4>
          <SwapWidget defaultInputTokenAddress={"0x5894cFEbFdEdBe61d01F20140f41c5c49AedAe97"} tokenList={SWAP_WIDGET_TOKEN_LIST} />
        </div>
      )}
    </div>
  );
};

export default UcrRedeem;
