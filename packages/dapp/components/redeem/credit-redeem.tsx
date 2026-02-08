import { BigNumber, ethers } from "ethers";
import { useState } from "react";
import { SwapWidget } from "@uniswap/widgets";
import { ensureERC20Allowance } from "@/lib/contracts-shortcuts";
import { safeParseEther } from "@/lib/utils";
import useProtocolContracts from "@/components/lib/hooks/contracts/use-protocol-contracts";
import useBalances from "../lib/hooks/use-balances";
import useSigner from "../lib/hooks/use-signer";
import useTransactionLogger from "../lib/hooks/use-transaction-logger";
import Button from "../ui/button";
import PositiveNumberInput from "../ui/positive-number-input";
import useRouter from "../lib/hooks/use-router";
import useTrade from "../lib/hooks/use-trade";
import { SWAP_WIDGET_TOKEN_LIST, V3_ROUTER_ADDRESS } from "@/lib/utils";
import { getUniswapV3RouterContract } from "../utils/contracts";
import useWeb3 from "@/components/lib/hooks/use-web-3";

const CreditRedeem = ({ twapInteger }: { twapInteger: number }) => {
  const { provider, walletAddress } = useWeb3();
  const signer = useSigner();
  const [balances, refreshBalances] = useBalances();
  const [, doTransaction, doingTransaction] = useTransactionLogger();
  const protocolContracts = useProtocolContracts();

  const [inputVal, setInputVal] = useState("0");
  // cspell: disable-next-line
  const [selectedRedeemToken, setSelectedRedeemToken] = useState("DOLLAR");
  const [quoteAmount, lastQuoteAmount] = useRouter(selectedRedeemToken, inputVal);
  const currentlyAbovePeg = twapInteger > 1;

  if (!walletAddress || !signer) {
    return <span>Connect wallet</span>;
  }

  if (!protocolContracts || !balances) {
    return <span>· · ·</span>;
  }

  const redeemCredit = async (amount: BigNumber) => {
    const contracts = await protocolContracts;
    if (contracts.creditToken && contracts.creditNftManagerFacet && contracts.dollarToken) {
      // cspell: disable-next-line
      await ensureERC20Allowance("CREDIT -> CreditNftManagerFacet", contracts.creditToken, amount, signer, contracts.creditNftManagerFacet.address);
      await (await contracts.creditNftManagerFacet.connect(signer).burnCreditTokensForDollars(amount)).wait();
      refreshBalances();
      // cspell: disable-next-line
      if (provider && quoteAmount && selectedRedeemToken !== "DOLLAR") {
        const routerContract = getUniswapV3RouterContract(V3_ROUTER_ADDRESS, provider);
        await (await routerContract.connect(signer).approveMax(contracts.dollarToken.address)).wait();
        await useTrade(selectedRedeemToken, quoteAmount);
        refreshBalances();
      }
    }
  };

  const handleRedeem = () => {
    const amount = extractValidAmount();
    if (amount) {
      // cspell: disable-next-line
      doTransaction("Redeeming CREDIT...", async () => {
        setInputVal("");
        await redeemCredit(amount);
      });
    }
  };

  const extractValidAmount = (val: string = inputVal): null | BigNumber => {
    const amount = safeParseEther(val);
    return amount && amount.gt(BigNumber.from(0)) && amount.lte(balances.credit) ? amount : null;
  };

  const submitEnabled = !!(extractValidAmount() && !doingTransaction);

  const handleMax = () => {
    const creditTokenValue = ethers.utils.formatEther(balances.credit);
    setInputVal(parseInt(creditTokenValue).toString());
  };

  function onChangeValue(e: React.ChangeEvent<HTMLInputElement>) {
    setSelectedRedeemToken(e.target.value);
  }

  return (
    <div>
      {currentlyAbovePeg ? (
        <div>
          <h4>TWAP is above peg</h4>
          <div onChange={onChangeValue}>
            <p>Please select a token to redeem for:</p>
            {/* cspell: disable-next-line */}
            <input type="radio" id="tokenChoice1" name="redeemToken" value="DOLLAR" checked={selectedRedeemToken === "DOLLAR"} readOnly />
            {/* cspell: disable-next-line */}
            <label htmlFor="tokenChoice1">DOLLAR</label>

            <input type="radio" id="tokenChoice2" name="redeemToken" value="USDC" checked={selectedRedeemToken === "USDC"} readOnly />
            <label htmlFor="tokenChoice2">USDC</label>

            <input type="radio" id="tokenChoice3" name="redeemToken" value="DAI" checked={selectedRedeemToken === "DAI"} readOnly />
            <label htmlFor="tokenChoice3">DAI</label>

            <input type="radio" id="tokenChoice4" name="redeemToken" value="USDT" checked={selectedRedeemToken === "USDT"} readOnly />
            <label htmlFor="tokenChoice4">USDT</label>
          </div>
          <div>
            {/* cspell: disable-next-line */}
            <PositiveNumberInput placeholder="CREDIT Amount" value={inputVal} onChange={setInputVal} />
            <span onClick={handleMax}>MAX</span>
          </div>
          {/* cspell: disable-next-line */}
          {inputVal && selectedRedeemToken === "DOLLAR" && quoteAmount && (
            <div>
              {/* cspell: disable-next-line */}
              {inputVal} CREDIT -&gt; {quoteAmount} DOLLAR.
            </div>
          )}
          {/* cspell: disable-next-line */}
          {inputVal && selectedRedeemToken !== "DOLLAR" && quoteAmount && lastQuoteAmount && (
            <div>
              {/* cspell: disable-next-line */}
              {inputVal} CREDIT -&gt; {quoteAmount} DOLLAR -&gt; {lastQuoteAmount} {selectedRedeemToken}.
            </div>
          )}
          <Button onClick={handleRedeem} disabled={!submitEnabled}>
            {/* cspell: disable-next-line */}
            Redeem CREDIT for {selectedRedeemToken}
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

export default CreditRedeem;
