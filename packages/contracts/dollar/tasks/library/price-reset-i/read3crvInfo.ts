import { ICurveFactory } from "../../../artifacts/types/ICurveFactory";
import { IMetaPool } from "../../../artifacts/types/IMetaPool";
import { UbiquityAlgorithmicDollar } from "../../../artifacts/types/UbiquityAlgorithmicDollar";

interface Params {
  curvePoolFactory: ICurveFactory;
  metaPool: IMetaPool;
  DAI: string;
  USDT: string;
  uAD: UbiquityAlgorithmicDollar;
  USDC: string;
  ethers: any;
}

export async function read3crvInfo({ curvePoolFactory, metaPool, DAI, USDT, uAD, USDC, ethers }: Params) {
  const indices = await curvePoolFactory.get_coin_indices(metaPool.address, DAI, USDT);

  const indices2 = await curvePoolFactory.get_coin_indices(metaPool.address, uAD.address, USDC);
  let dyDAI2USDT = await metaPool["get_dy_underlying(int128,int128,uint256)"](indices[0], indices[1], ethers.utils.parseEther("1"));

  let dyuAD2USDC = await metaPool["get_dy_underlying(int128,int128,uint256)"](indices2[0], indices2[1], ethers.utils.parseEther("1"));

  let dyuAD2DAI = await metaPool["get_dy_underlying(int128,int128,uint256)"](indices2[0], indices[0], ethers.utils.parseEther("1"));

  let dyuAD2USDT = await metaPool["get_dy_underlying(int128,int128,uint256)"](indices2[0], indices[1], ethers.utils.parseEther("1"));
  return { dyDAI2USDT, dyuAD2USDC, dyuAD2DAI, dyuAD2USDT, indices, indices2 };
}
