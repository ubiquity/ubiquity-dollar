import BondingPool from "./BondingPool";
import { goldenPool, PoolData } from "./lib/pools";
import SectionTitle from "./lib/SectionTitle";

const MultiplicationPool = ({ isWhitelisted, poolsData }: { isWhitelisted: boolean; poolsData: { [key: string]: PoolData } }) => {
  return (
    <div className="party-container">
      <SectionTitle title="Golden Pool" subtitle="Multiply and exchange" />

      <div className="w-2/3 mx-auto">
        <BondingPool isWhitelisted={isWhitelisted} poolData={poolsData[goldenPool.tokenAddress]} {...goldenPool} />
      </div>
    </div>
  );
};

export default MultiplicationPool;
