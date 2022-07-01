import * as widget from "@/ui/widget";
import { goldenPool, PoolData } from "./lib/pools";
import StakingPool from "./StakingPool";

type MultiplicationPoolParams = {
  enabled: boolean;
  poolsData: { [key: string]: PoolData };
  onDeposit: ({ token, amount }: { token: string; amount: number }) => unknown;
};

const MultiplicationPool = ({ enabled, poolsData, onDeposit }: MultiplicationPoolParams) => {
  return (
    <widget.Container>
      <widget.Title text="Golden Pool" />
      <widget.SubTitle text="Multiply and exchanges" />

      <div className="mx-auto w-2/3">
        <StakingPool
          enabled={enabled}
          poolData={poolsData[goldenPool.tokenAddress]}
          onDeposit={({ amount }) => onDeposit({ token: goldenPool.tokenAddress, amount })}
          {...goldenPool}
        />
      </div>
    </widget.Container>
  );
};

export default MultiplicationPool;
