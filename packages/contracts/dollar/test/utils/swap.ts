import { BigNumber, Signer } from "ethers";
import { ERC20 } from "../../artifacts/types/ERC20";
import { UbiquityAlgorithmicDollar } from "../../artifacts/types/UbiquityAlgorithmicDollar";
import { IMetaPool } from "../../artifacts/types/IMetaPool";

export async function swap3CRVtoUAD(curveMetaPool: IMetaPool, crvToken: ERC20, amount: BigNumber, signer: Signer): Promise<BigNumber> {
  const dy3CRVtoUAD = await curveMetaPool["get_dy(int128,int128,uint256)"](1, 0, amount);
  const expectedMinUAD = dy3CRVtoUAD.div(100).mul(99);
  // signer need to approve metaPool for sending its coin
  await crvToken.connect(signer).approve(curveMetaPool.address, 0);
  await crvToken.connect(signer).approve(curveMetaPool.address, amount);
  // secondAccount swap   3CRV=> x uAD
  await curveMetaPool.connect(signer)["exchange(int128,int128,uint256,uint256)"](1, 0, amount, expectedMinUAD);
  return dy3CRVtoUAD;
}
export async function swapUADto3CRV(curveMetaPool: IMetaPool, uAD: UbiquityAlgorithmicDollar, amount: BigNumber, signer: Signer): Promise<BigNumber> {
  const dyuADto3CRV = await curveMetaPool["get_dy(int128,int128,uint256)"](0, 1, amount);
  const expectedMin3CRV = dyuADto3CRV.div(100).mul(99);

  // signer need to approve metaPool for sending its coin
  await uAD.connect(signer).approve(curveMetaPool.address, amount);
  // secondAccount swap   3CRV=> x uAD
  await curveMetaPool.connect(signer)["exchange(int128,int128,uint256,uint256)"](0, 1, amount, expectedMin3CRV);
  return dyuADto3CRV;
}

export async function swapDAItoUAD(curveMetaPool: IMetaPool, daiToken: ERC20, amount: BigNumber, signer: Signer): Promise<BigNumber> {
  const dyDAITouAD = await curveMetaPool["get_dy_underlying(int128,int128,uint256)"](1, 0, amount);
  const expectedMinUAD = dyDAITouAD.div(100).mul(99);

  // secondAccount need to approve metaPool for sending its uAD
  await daiToken.connect(signer).approve(curveMetaPool.address, amount);
  // swap 1 DAI  =>  1uAD
  await curveMetaPool.connect(signer)["exchange_underlying(int128,int128,uint256,uint256)"](1, 0, amount, expectedMinUAD);
  return dyDAITouAD;
}

export async function swapUADtoDAI(curveMetaPool: IMetaPool, uAD: UbiquityAlgorithmicDollar, amount: BigNumber, signer: Signer): Promise<BigNumber> {
  const dyuADtoDAI = await curveMetaPool["get_dy_underlying(int128,int128,uint256)"](0, 1, amount);
  const expectedMinDAI = dyuADtoDAI.div(100).mul(99);

  // secondAccount need to approve metaPool for sending its uAD
  await uAD.connect(signer).approve(curveMetaPool.address, amount);
  // secondAccount swap 1uAD => 1 DAI
  await curveMetaPool.connect(signer)["exchange_underlying(int128,int128,uint256,uint256)"](0, 1, amount, expectedMinDAI);
  return dyuADtoDAI;
}

// swap back and forth small amount to trigger an oracle update
export async function swapToUpdateOracle(curveMetaPool: IMetaPool, crvToken: ERC20, uAD: UbiquityAlgorithmicDollar, signer: Signer): Promise<void> {
  await swapUADto3CRV(curveMetaPool, uAD, BigNumber.from("10"), signer);
  const amount = await crvToken.balanceOf(await signer.getAddress());
  await swap3CRVtoUAD(curveMetaPool, crvToken, amount, signer);
}
