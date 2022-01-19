import { format, round } from "./lib/utils";
import SectionTitle from "./lib/SectionTitle";

const Liquidate = ({ accumulated }: { accumulated: number | null }) => {
  return (
    <div className="party-container">
      <SectionTitle title="Liquidate" subtitle="Exit the game; sell uAR for ETH" />
      <div className="text-lg mb-2">You have</div>
      <div className="text-4xl mb-10 text-accent drop-shadow-light">{accumulated !== null ? format(round(accumulated)) : "????"} uAR</div>
      <a className="btn-primary" target="_blank" href="https://app.uniswap.org/">
        Exchange for ETH
      </a>
    </div>
  );
};

export default Liquidate;
