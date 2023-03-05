import { PossibleProviders } from "@/lib/hooks/useWeb3";
import { ethers } from "ethers";
import { getERC20Contract, getUniswapV2FactoryContract, getUniswapV3PoolContract } from "@/components/utils/contracts";
import { ERC20 } from '../../../types/ERC20';
export type UniswapData = {
  poolAddress: string;
  contract1: ERC20;
  contract2: ERC20;
  token1: string;
  token2: string;
  decimal1: number;
  decimal2: number;
  balance1: ethers.BigNumber;
  balance2: ethers.BigNumber;
  symbol1: string;
  symbol2: string;
  name1: string;
  name2: string;
};

type UniswapDataRequest = {
  address: string;
  version: "v2" | "v3";
};

async function fetchUniswapPoolsData(pools: UniswapDataRequest[], provider: NonNullable<PossibleProviders>): Promise<{ [poolAddress: string]: UniswapData }> {
  const getUniPoolFullData = async (poolAddress: string, isV2: boolean): Promise<UniswapData> => {
    const pool = isV2 ? getUniswapV2FactoryContract(poolAddress, provider) : getUniswapV3PoolContract(poolAddress, provider);
    const t1 = getERC20Contract(await pool.token0(), provider) as ERC20;
    const t2 = getERC20Contract(await pool.token1(), provider) as ERC20;
    const d1 = await t1.decimals();
    const d2 = await t2.decimals();
    const b1 = await t1.balanceOf(pool.address);
    const b2 = await t2.balanceOf(pool.address);

    return {
      poolAddress: poolAddress,
      contract1: t1,
      contract2: t2,
      token1: t1.address,
      token2: t2.address,
      decimal1: d1,
      decimal2: d2,
      balance1: b1,
      balance2: b2,
      symbol1: await t1.symbol(),
      symbol2: await t2.symbol(),
      name1: await t1.name(),
      name2: await t2.name(),
    };
  };

  const uniswapPoolsData = (await Promise.all(pools.map(({ address, version }) => getUniPoolFullData(address, version === "v2")))).reduce(
    (acc, uniswapPoolData) => {
      return { ...acc, [uniswapPoolData.poolAddress]: uniswapPoolData };
    },
    {}
  );

  return uniswapPoolsData;
}

export default fetchUniswapPoolsData;
