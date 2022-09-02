import { ethers } from "ethers";
import { ERC20 } from "../../../artifacts/types/ERC20";
import { IMetaPool } from "../../../artifacts/types/IMetaPool";
import { UbiquityAlgorithmicDollar } from "../../../artifacts/types/UbiquityAlgorithmicDollar";

interface Params {
  uAD: UbiquityAlgorithmicDollar;
  treasuryAddr: string;
  curveToken: ERC20;
  metaPool: IMetaPool;
  bondingAddr: string;
  ethers: typeof ethers;
  amount: any;
}

export async function balancesAndCalculations({ uAD, treasuryAddr, curveToken, metaPool, bondingAddr, ethers, amount }: Params) {
  const uadTreasuryBalanceBefore = await uAD.balanceOf(treasuryAddr),
    crvTreasuryBalanceBefore = await curveToken.balanceOf(treasuryAddr),
    bondingMetaPoolLPBalanceBefore = await metaPool.balanceOf(bondingAddr),
    LPBal = ethers.utils.formatEther(bondingMetaPoolLPBalanceBefore),
    expectedUAD = await metaPool["calc_withdraw_one_coin(uint256,int128)"](amount, 0),
    expectedUADStr = ethers.utils.formatEther(expectedUAD),
    expectedCRV = await metaPool["calc_withdraw_one_coin(uint256,int128)"](amount, 1),
    expectedCRVStr = ethers.utils.formatEther(expectedCRV);

  return { LPBal, expectedUADStr, expectedCRVStr, crvTreasuryBalanceBefore, uadTreasuryBalanceBefore };
}
