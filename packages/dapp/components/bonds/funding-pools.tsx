import BondingPool from "./bonding-pool";
import { PoolData, pools } from "./lib/pools";

type FundingPoolParams = {
  enabled: boolean;
  poolsData: { [key: string]: PoolData };
  onDeposit: ({ token, amount }: { token: string; amount: number }) => unknown;
};

const FundingPools = ({ enabled, poolsData, onDeposit }: FundingPoolParams) => {
  return (
    <div>
      <h2>Funding Pools</h2>
      {/* cspell: disable-next-line */}
      <h3>Sell LP, get uCR over the course of 5 days</h3>
      <div>
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
