import BondingPool from "./BondingPool";
import { PoolData, pools } from "./lib/pools";
import SectionTitle from "./lib/SectionTitle";

type FundingPoolParams = {
  enabled: boolean;
  poolsData: { [key: string]: PoolData };
  onDeposit: ({ token, amount }: { token: string; amount: number }) => unknown;
};

const FundingPools = ({ enabled, poolsData, onDeposit }: FundingPoolParams) => {
  return (
    <div className="party-container">
      <SectionTitle title="Funding Pools" subtitle="Sell LP, get uAR over the course of 5 days" />
      <div className="grid grid-cols-2 gap-8">
        {pools.map((pool) => (
          <BondingPool
            key={pool.name}
            enabled={enabled}
            poolData={poolsData[pool.tokenAddress]}
            onDeposit={({ amount }) => onDeposit({ token: pool.tokenAddress, amount })}
            {...pool}
          />
        ))}
      </div>
    </div>
  );
};

export default FundingPools;
