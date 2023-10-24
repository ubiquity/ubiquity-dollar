import { Percent, TradeType } from "@uniswap/sdk-core";
import { AlphaRouter } from "@uniswap/smart-order-router";
import { BigNumber } from "@ethersproject/bignumber";
import useWeb3 from "@/components/lib/hooks/use-web-3";
import { DOLLAR_TOKEN, USDC_TOKEN, USDT_TOKEN, DAI_TOKEN, parseAmount, V3_ROUTER_ADDRESS } from "../utils";

const useTrade = async (selectedToken: string, amountIn = "0") => {
  const { provider, walletAddress } = useWeb3();

  let selectedTokenObject;
  const parsedAmountIn = parseAmount(amountIn, DOLLAR_TOKEN);

  if (selectedToken === "USDC") {
    selectedTokenObject = USDC_TOKEN;
  } else if (selectedToken === "DAI") {
    selectedTokenObject = DAI_TOKEN;
  } else if (selectedToken === "USDT") {
    selectedTokenObject = USDT_TOKEN;
  } else {
    selectedTokenObject = USDC_TOKEN;
  }

  if (provider && walletAddress) {
    const router = new AlphaRouter({ chainId: 1, provider: provider });

    const route = await router.route(parsedAmountIn, selectedTokenObject, TradeType.EXACT_INPUT, {
      recipient: walletAddress,
      slippageTolerance: new Percent(5, 100),
      deadline: Math.floor(Date.now() / 1000 + 1800),
    });
    if (route) {
      const transaction = {
        data: route?.methodParameters?.calldata,
        to: V3_ROUTER_ADDRESS,
        value: BigNumber.from(route?.methodParameters?.value),
        from: walletAddress,
        gasPrice: BigNumber.from(route.gasPriceWei),
      };

      return await provider.sendTransaction(JSON.stringify(transaction));
    }
  }
};

export default useTrade;
