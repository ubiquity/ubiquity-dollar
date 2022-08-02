import BondingPool from "./BondingPool";
import { goldenPool, PoolData } from "./lib/pools";

type MultiplicationPoolParams = {
  enabled: boolean;
  poolsData: { [key: string]: PoolData };
  onDeposit: ({ token, amount }: { token: string; amount: number }) => unknown;
};

const MultiplicationPool = ({ enabled, poolsData, onDeposit }: MultiplicationPoolParams) => {
  return (
    <div>
      <h2>Golden Pool</h2>
      <h3>Multiply and exchanges</h3>

      <div>
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
