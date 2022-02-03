import { format, round } from "./lib/utils";
import SectionTitle from "./lib/SectionTitle";

const Liquidate = ({ accumulated, poolAddress, uarUsdPrice }: { accumulated: number | null; poolAddress: string; uarUsdPrice: number | null }) => {
  const accumulatedInUsd = uarUsdPrice !== null && accumulated !== null ? accumulated * uarUsdPrice : null;
  return (
    <div className="party-container">
      <SectionTitle title="Liquidate" subtitle="Exit the game; sell uAR for ETH" />
      <div className="text-lg mb-2">You have</div>
      <div className="text-4xl mb-10 text-accent drop-shadow-light">
        {accumulated !== null ? format(round(accumulated)) : "????"} uAR
        {accumulatedInUsd !== null ? <span className="text-2xl opacity-50 ml-2 text-white">(${format(round(accumulatedInUsd))})</span> : null}
      </div>
      <a className="btn-primary" target="_blank" href={`https://v2.info.uniswap.org/pair/${poolAddress}`}>
        Exchange for ETH
      </a>
    </div>
  );
};

export default Liquidate;
