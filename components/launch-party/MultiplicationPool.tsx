import * as widget from "@/ui/widget";
import BondingPool from "./BondingPool";
import { goldenPool, PoolData } from "./lib/pools";

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
        <BondingPool
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
