import BondingPool from "./BondingPool";
import { goldenPool } from "./data/pools";

const MultiplicationPool = () => {
  return (
    <div className="party-container">
      <h2 className="m-0 mb-2 tracking-widest uppercase text-xl">
        <span className="border-0 border-b-2 border-solid border-white">Golden Pool</span>
      </h2>
      <p className="m-0 mb-4 font-light tracking-wide">Multiply and exchange</p>
      <div className="w-2/3 mx-auto">
        <BondingPool {...goldenPool} />
      </div>
    </div>
  );
};

export default MultiplicationPool;
