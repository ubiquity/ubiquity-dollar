import BondingPool from "./BondingPool";
import { goldenPool, PoolData } from "./lib/pools";
import SectionTitle from "./lib/SectionTitle";

type MultiplicationPoolParams = {
  enabled: boolean;
  poolsData: { [key: string]: PoolData };
  onDeposit: ({ token, amount }: { token: string; amount: number }) => any;
};

const MultiplicationPool = ({ enabled, poolsData, onDeposit }: MultiplicationPoolParams) => {
  return (
    <div className="party-container">
      <SectionTitle title="Golden Pool" subtitle="Multiply and exchange" />

      <div className="w-2/3 mx-auto">
        <BondingPool
          enabled={enabled}
          poolData={poolsData[goldenPool.tokenAddress]}
          onDeposit={({ amount }) => onDeposit({ token: goldenPool.tokenAddress, amount })}
          {...goldenPool}
        />
      </div>
    </div>
  );
};

export default MultiplicationPool;
