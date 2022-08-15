import { ERC20, ERC20__factory } from "@/dollar-types";
import { UniswapV2Pair__factory, UniswapV3Pool__factory } from "@/fixtures/abi/types";
import { PossibleProviders } from "@/lib/hooks/useWeb3";
import { ethers } from "ethers";

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
    const pool = isV2 ? UniswapV2Pair__factory.connect(poolAddress, provider) : UniswapV3Pool__factory.connect(poolAddress, provider);
    const t1 = ERC20__factory.connect(await pool.token0(), provider);
    const t2 = ERC20__factory.connect(await pool.token1(), provider);
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

  const unipoolsData = (await Promise.all(pools.map(({ address, version }) => getUniPoolFullData(address, version === "v2")))).reduce((acc, unipoolData) => {
    return { ...acc, [unipoolData.poolAddress]: unipoolData };
  }, {});

  return unipoolsData;
}

export default fetchUniswapPoolsData;
