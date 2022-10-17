import { useEffect, useState } from "react";
import { AlphaRouter } from "@uniswap/smart-order-router";
import { Percent, TradeType } from "@uniswap/sdk-core";
import useWeb3 from "@/components/lib/hooks/useWeb3";
import { uAD, uCR, USDC, USDT, DAI, parseAmount } from "../utils";

const useRouter = (selectedToken: string, amountIn = "0"): string | undefined => {
  const [{ provider, walletAddress }] = useWeb3();
  const [quotePrice, setQuotePrice] = useState<string>();

  async function getQuote() {
    let selectedTokenObject;
    const parsedAmountIn = parseAmount(amountIn, uCR);

    if (selectedToken === "USDC") {
      selectedTokenObject = USDC;
    } else if (selectedToken === "DAI") {
      selectedTokenObject = DAI;
    } else if (selectedToken === "USDT") {
      selectedTokenObject = USDT;
    } else {
      selectedTokenObject = uAD;
    }

    if (provider && walletAddress) {
      const router = new AlphaRouter({ chainId: 1, provider: provider });

      const route = await router.route(parsedAmountIn, selectedTokenObject, TradeType.EXACT_INPUT, {
        recipient: walletAddress,
        slippageTolerance: new Percent(5, 100),
        deadline: Math.floor(Date.now() / 1000 + 1800),
      });

      setQuotePrice(route?.quote.toFixed(2));
    }
  }

  useEffect(() => {
    getQuote();
  }, [selectedToken, amountIn]);

  return quotePrice;
};

export default useRouter;
