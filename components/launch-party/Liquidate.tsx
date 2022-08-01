import { ButtonLink } from "@/ui";
import * as widget from "@/ui/widget";
import { format, round } from "./lib/utils";

const Liquidate = ({ accumulated, poolAddress, uarUsdPrice }: { accumulated: number | null; poolAddress: string; uarUsdPrice: number | null }) => {
  const accumulatedInUsd = uarUsdPrice !== null && accumulated !== null ? accumulated * uarUsdPrice : null;
  return (
    <widget.Container>
      <widget.Title text="Liquidate" />
      <widget.SubTitle text="Exit the game; sell uCR for ETH" />
      <div>You have</div>
      <div>
        {accumulated !== null ? format(round(accumulated)) : "????"} uCR
        {accumulatedInUsd !== null ? <span>(${format(round(accumulatedInUsd))})</span> : null}
      </div>
      <ButtonLink target="_blank" href={`https://v2.info.uniswap.org/pair/${poolAddress}`}>
        Exchange for ETH
      </ButtonLink>
    </widget.Container>
  );
};

export default Liquidate;
