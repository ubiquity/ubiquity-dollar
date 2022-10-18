import { useEffect, useState } from "react";
import { AlphaRouter } from "@uniswap/smart-order-router";
import { Percent, TradeType } from "@uniswap/sdk-core";
import useWeb3 from "@/components/lib/hooks/useWeb3";
import { uAD, uCR, USDC, USDT, DAI, parseAmount } from "../utils";

const useRouter = (selectedToken: string, amountIn = "0"): [string | undefined, string | undefined] => {
  const [{ provider, walletAddress }] = useWeb3();
  const [quotePrice, setQuotePrice] = useState<string | undefined>();
  const [lastQuotePrice, setLastQuotePrice] = useState<string | undefined>();

  async function getQuote() {
    let selectedTokenObject;
    const parsedAmountIn = parseAmount(amountIn, uCR);

    if (selectedToken === "USDC") {
      selectedTokenObject = USDC;
    } else if (selectedToken === "DAI") {
      selectedTokenObject = DAI;
    } else {
      selectedTokenObject = USDT;
    }

    if (provider && walletAddress) {
      const router = new AlphaRouter({ chainId: 1, provider: provider });

      const route1 = await router.route(parsedAmountIn, uAD, TradeType.EXACT_INPUT, {
        recipient: walletAddress,
        slippageTolerance: new Percent(5, 100),
        deadline: Math.floor(Date.now() / 1000 + 1800),
      });
      setQuotePrice(route1?.quote.toFixed(2));

      console.log("Expected uAD Value : ", route1?.quote.toFixed(2));

      if (route1) {
        const parsed_uAD_amount = parseAmount(route1.quote.toFixed(2), uAD);

        const route2 = await router.route(parsed_uAD_amount, selectedTokenObject, TradeType.EXACT_INPUT, {
          recipient: walletAddress,
          slippageTolerance: new Percent(5, 100),
          deadline: Math.floor(Date.now() / 1000 + 1800),
        });
        console.log(`Expected ${selectedToken} Value : `, route2?.quote.toFixed(2));
        setLastQuotePrice(route2?.quote.toFixed(2));
      }
    }
  }

  useEffect(() => {
    getQuote();
  }, [selectedToken, amountIn]);

  return [quotePrice, lastQuotePrice];
};

export default useRouter;
