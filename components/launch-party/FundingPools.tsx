import * as widget from "../ui/widget";
import BondingPool from "./BondingPool";
import { PoolData, pools } from "./lib/pools";

type FundingPoolParams = {
  enabled: boolean;
  poolsData: { [key: string]: PoolData };
  onDeposit: ({ token, amount }: { token: string; amount: number }) => unknown;
};

const FundingPools = ({ enabled, poolsData, onDeposit }: FundingPoolParams) => {
  return (
    <widget.Container>
      <widget.Title text="Funding Pools" />
      <widget.SubTitle text="Sell LP, get uCR over the course of 5 days" />
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
    </widget.Container>
  );
};

export default FundingPools;
