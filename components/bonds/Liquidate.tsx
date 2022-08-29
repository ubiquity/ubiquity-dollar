import { ButtonLink } from "../ui/Button";
import { format, round } from "./lib/utils";

const Liquidate = ({ accumulated, poolAddress, uarUsdPrice }: { accumulated: number | null; poolAddress: string; uarUsdPrice: number | null }) => {
  const accumulatedInUsd = uarUsdPrice !== null && accumulated !== null ? accumulated * uarUsdPrice : null;
  return (
    <div>
      <h2>Liquidate</h2>
      <h3>Exit the game; sell uCR for ETH</h3>
      <div>You have</div>
      <div>
        {accumulated !== null ? format(round(accumulated)) : "????"} uCR
        {accumulatedInUsd !== null ? <span>(${format(round(accumulatedInUsd))})</span> : null}
      </div>
      <ButtonLink target="_blank" href={`https://v2.info.uniswap.org/pair/${poolAddress}`}>
        Exchange for ETH
      </ButtonLink>
    </div>
  );
};

export default Liquidate;
