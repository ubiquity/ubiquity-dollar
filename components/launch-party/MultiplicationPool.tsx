import BondingPool from "./BondingPool";
import { goldenPool } from "./lib/pools";
import SectionTitle from "./lib/SectionTitle";

const MultiplicationPool = () => {
  return (
    <div className="party-container">
      <SectionTitle title="Golden Pool" subtitle="Multiply and exchange" />
      <div className="w-2/3 mx-auto">
        <BondingPool {...goldenPool} />
      </div>
    </div>
  );
};

export default MultiplicationPool;
