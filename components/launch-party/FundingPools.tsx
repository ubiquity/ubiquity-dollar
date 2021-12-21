import BondingPool from "./BondingPool";
import { pools } from "./data/pools";

const FundingPools = () => {
  return (
    <div className="party-container">
      <h2 className="m-0 mb-2 tracking-widest uppercase text-xl">Funding Pools</h2>
      <p className="m-0 mb-4 font-light tracking-wide">Sell LP, get uAR over the course of 5 days</p>
      <div className="grid grid-cols-2 gap-8">
        {pools.map((pool) => (
          <BondingPool {...pool} />
        ))}
      </div>
    </div>
  );
};

export default FundingPools;
