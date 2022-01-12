import BondingPool from "./BondingPool";
import { pools } from "./lib/pools";
import SectionTitle from "./lib/SectionTitle";

const FundingPools = ({ isWhitelisted }: { isWhitelisted: boolean }) => {
  return (
    <div className="party-container">
      <SectionTitle title="Funding Pools" subtitle="Sell LP, get uAR over the course of 5 days" />
      <div className="grid grid-cols-2 gap-8">
        {pools.map((pool) => (
          <BondingPool key={pool.token1 + "-" + pool.token2} isWhitelisted={isWhitelisted} {...pool} />
        ))}
      </div>
    </div>
  );
};

export default FundingPools;
