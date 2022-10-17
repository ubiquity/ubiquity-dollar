import { BigNumber, Contract, ethers } from "ethers";
import { useState } from "react";
import { SwapWidget } from "@uniswap/widgets";
import { ensureERC20Allowance } from "@/lib/contracts-shortcuts";
import { safeParseEther } from "@/lib/utils";
import useDeployedContracts from "../lib/hooks/contracts/useDeployedContracts";
import useManagerManaged from "../lib/hooks/contracts/useManagerManaged";
import useEffectAsync from "@/components/lib/hooks/useEffectAsync";
import useBalances from "../lib/hooks/useBalances";
import useSigner from "../lib/hooks/useSigner";
import useTransactionLogger from "../lib/hooks/useTransactionLogger";
import useWalletAddress from "../lib/hooks/useWalletAddress";
import Button from "../ui/Button";
import PositiveNumberInput from "../ui/PositiveNumberInput";
import useRouter from "../lib/hooks/useRouter";
import { USDC_ADDRESS, SWAP_WIDGET_TOKEN_LIST } from "@/lib/utils";

const UcrRedeem = () => {
  const [walletAddress] = useWalletAddress();
  const signer = useSigner();
  const [balances, refreshBalances] = useBalances();
  const [, doTransaction, doingTransaction] = useTransactionLogger();
  const deployedContracts = useDeployedContracts();
  const managedContracts = useManagerManaged();

  const [twapPrice, setTwapPrice] = useState<ethers.BigNumber | null>(null);
  const [inputVal, setInputVal] = useState("0");
  const [selectedRedeemToken, setSelectedRedeemToken] = useState("USDC");
  const [quotePrice, lastQuotePrice] = useRouter(selectedRedeemToken, inputVal);

  if (!walletAddress || !signer) {
    return <span>Connect wallet</span>;
  }

  if (!managedContracts || !deployedContracts || !balances) {
    return <span>· · ·</span>;
  }

  useEffectAsync(async () => {
    if (managedContracts) {
      setTwapPrice(await managedContracts.dollarTwapOracle.consult(managedContracts.dollarToken.address));
    }
  }, [managedContracts]);

  let twapInteger = 0;
  let abovePeg = false;
  if (twapPrice) {
    twapInteger = (twapPrice as unknown as number) / 1e18;
    abovePeg = twapInteger > 1;
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

  function onChangeValue(e: React.ChangeEvent<HTMLInputElement>) {
    setSelectedRedeemToken(e.target.value);
  }

  return (
    <div>
      {!abovePeg ? (
        <div>
          <h4>TWAP is above peg</h4>
          <div>uCR-&gt;uAD-&gt;USDC/DAI/USDT</div>
          <div onChange={onChangeValue}>
            <p>Please select a token to redeem for:</p>

            <input type="radio" id="tokenChoice1" name="redeemToken" value="USDC" checked={selectedRedeemToken === "USDC"} readOnly />
            <label htmlFor="tokenChoice1">USDC</label>

            <input type="radio" id="tokenChoice2" name="redeemToken" value="DAI" checked={selectedRedeemToken === "DAI"} readOnly />
            <label htmlFor="tokenChoice2">DAI</label>

            <input type="radio" id="tokenChoice3" name="redeemToken" value="USDT" checked={selectedRedeemToken === "USDT"} readOnly />
            <label htmlFor="tokenChoice3">USDT</label>
          </div>
          <div>
            <PositiveNumberInput placeholder="uCR Amount" value={inputVal} onChange={setInputVal} />
            <span onClick={handleMax}>MAX</span>
          </div>
          {inputVal && quotePrice && lastQuotePrice && (
            <div>
              {inputVal} uCR -&gt; {quotePrice} uAD -&gt; {lastQuotePrice} {selectedRedeemToken}.
            </div>
          )}
          <Button onClick={handleRedeem} disabled={!submitEnabled}>
            Redeem uCR for uAD
          </Button>
          {lastQuotePrice && (
            <div>
              After successfully redeemed uCR for uAD
              <br />
              please use below swap widget to get {lastQuotePrice} {selectedRedeemToken}
            </div>
          )}
          <div className="Uniswap">
            <SwapWidget
              defaultInputTokenAddress={"0x0F644658510c95CB46955e55D7BA9DDa9E9fBEc6"}
              defaultOutputTokenAddress={USDC_ADDRESS}
              tokenList={SWAP_WIDGET_TOKEN_LIST}
            />
          </div>
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
