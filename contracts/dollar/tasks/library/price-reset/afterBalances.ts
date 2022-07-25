import { BigNumber, ethers } from "ethers";
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
  LPBal: string;
  crvTreasuryBalanceBefore: BigNumber;
  uadTreasuryBalanceBefore: BigNumber;
}

export async function afterBalances({
  uAD,
  treasuryAddr,
  curveToken,
  metaPool,
  bondingAddr,
  ethers,
  LPBal,
  crvTreasuryBalanceBefore,
  uadTreasuryBalanceBefore,
}: Params) {
  const uadTreasuryBalanceAfter = await uAD.balanceOf(treasuryAddr);
  const crvTreasuryBalanceAfter = await curveToken.balanceOf(treasuryAddr);
  const metaPoolLPBalanceAfter = await metaPool.balanceOf(bondingAddr);
  const LPBalAfter = ethers.utils.formatEther(metaPoolLPBalanceAfter);
  console.log(`from ${LPBal} to ${LPBalAfter} uAD-3CRV LP token
      `);

  const crvTreasuryBalanceBeforeStr = ethers.utils.formatEther(crvTreasuryBalanceBefore);
  const crvTreasuryBalanceAfterStr = ethers.utils.formatEther(crvTreasuryBalanceAfter);
  console.log(`Treasury 3CRV balance from ${crvTreasuryBalanceBeforeStr} to ${crvTreasuryBalanceAfterStr}
        `);
  const balTreasuryUadBeforeStr = ethers.utils.formatEther(uadTreasuryBalanceBefore);
  const balTreasuryUadAfterStr = ethers.utils.formatEther(uadTreasuryBalanceAfter);
  console.log(`Treasury uAD balance from ${balTreasuryUadBeforeStr} to ${balTreasuryUadAfterStr}
        `);
}
