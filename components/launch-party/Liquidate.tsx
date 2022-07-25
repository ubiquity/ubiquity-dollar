import { ButtonLink } from "@/ui";
import * as widget from "@/ui/widget";
import { format, round } from "./lib/utils";

const Liquidate = ({ accumulated, poolAddress, uarUsdPrice }: { accumulated: number | null; poolAddress: string; uarUsdPrice: number | null }) => {
  const accumulatedInUsd = uarUsdPrice !== null && accumulated !== null ? accumulated * uarUsdPrice : null;
  return (
    <widget.Container className="text-center">
      <widget.Title text="Liquidate" />
      <widget.SubTitle text="Exit the game; sell uCR for ETH" />
      <div className="mb-2 text-lg">You have</div>
      <div className="mb-10 text-4xl text-accent drop-shadow-light">
        {accumulated !== null ? format(round(accumulated)) : "????"} uCR
        {accumulatedInUsd !== null ? <span className="ml-2 text-2xl text-white opacity-50">(${format(round(accumulatedInUsd))})</span> : null}
      </div>
      <ButtonLink target="_blank" href={`https://v2.info.uniswap.org/pair/${poolAddress}`}>
        Exchange for ETH
      </ButtonLink>
    </widget.Container>
  );
};

export default Liquidate;
