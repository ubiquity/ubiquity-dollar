import { describe, it } from "mocha";
import { BigNumber, Signer } from "ethers";
import { expect } from "./setup";
import { bondingSetupV2, deposit } from "./BondingSetupV2";
import { MasterChefV2 } from "../artifacts/types/MasterChefV2";
import { IMetaPool } from "../artifacts/types/IMetaPool";
import { mineNBlock } from "./utils/hardhatNode";
import { isAmountEquivalent } from "./utils/calc";
import { UbiquityGovernance } from "../artifacts/types/UbiquityGovernance";
import { BondingV2 } from "../artifacts/types/BondingV2";
import { BondingShareV2 } from "../artifacts/types/BondingShareV2";

describe("MasterChefV2", () => {
  const one: BigNumber = BigNumber.from(10).pow(18); // one = 1 ether = 10^18
  let masterChefV2: MasterChefV2;

  let secondAccount: Signer;
  let fourthAccount: Signer;
  let secondAddress: string;
  let metaPool: IMetaPool;
  let uGOV: UbiquityGovernance;
  let bondingV2: BondingV2;
  let bondingShareV2: BondingShareV2;

  beforeEach(async () => {
    ({ masterChefV2, bondingV2, bondingShareV2, uGOV, secondAccount, fourthAccount, metaPool } = await bondingSetupV2());
    secondAddress = await secondAccount.getAddress();
    // for testing purposes set the week equal to one block
    await bondingV2.setBlockCountInAWeek(1);
  });

  describe("deposit", () => {
    it("should be able to calculate pending UBQ", async () => {
      const totalLPBeforeAdd = await bondingShareV2.totalLP();
      const balanceBondingBeforeAdd = await metaPool.balanceOf(bondingV2.address);
      const amount = one.mul(100);
      const { id, bsAmount, shares, creationBlock, endBlock } = await deposit(secondAccount, amount, 1);
      const totalLPAfterAdd = await bondingShareV2.totalLP();
      const balanceBondingAfterAdd = await metaPool.balanceOf(bondingV2.address);
      expect(totalLPAfterAdd).to.equal(totalLPBeforeAdd.add(amount));
      expect(balanceBondingAfterAdd).to.equal(balanceBondingBeforeAdd.add(amount));
      expect(id).to.equal(1);
      expect(bsAmount).to.equal(1);
      const detail = await bondingShareV2.getBond(id);
      expect(detail.lpAmount).to.equal(amount);
      expect(detail.lpFirstDeposited).to.equal(amount);
      expect(detail.minter).to.equal(await secondAccount.getAddress());
      expect(detail.lpRewardDebt).to.equal(0);
      expect(detail.creationBlock).to.equal(creationBlock);
      expect(detail.endBlock).to.equal(endBlock);
      const shareDetail = await masterChefV2.getBondingShareInfo(id);
      expect(shareDetail[0]).to.equal(shares);
      let totShares = await masterChefV2.totalShares();
      let percentage = shareDetail[0].mul(100).div(totShares);
      expect(percentage).to.equal(100);
      // user amount is equal to the amount of user's bonding share
      const tokensID = await bondingShareV2.holderTokens(secondAddress);

      // do not have pending rewards just after depositing
      let pendingUGOV = await masterChefV2.pendingUGOV(tokensID[0]);
      expect(pendingUGOV).to.equal(0);

      // as we have 100% of the shares we should get all the rewards per block
      await mineNBlock(1);
      const uGOVPerBlock = await masterChefV2.uGOVPerBlock();
      const uGOVmultiplier = await masterChefV2.uGOVmultiplier();
      pendingUGOV = await masterChefV2.pendingUGOV(tokensID[0]);
      const calculatedPendingUGOV = uGOVPerBlock.mul(uGOVmultiplier).div(one);

      const isPrecise = isAmountEquivalent(pendingUGOV.toString(), calculatedPendingUGOV.toString(), "0.00000000001");
      expect(isPrecise).to.be.true;
      await deposit(fourthAccount, amount, 1);

      totShares = await masterChefV2.totalShares();
      percentage = shareDetail[0].mul(100).div(totShares);

      expect(percentage).to.equal(50);
      // we mine 99 blocks plus 1 block to mine the deposit that makes 100 blocks
      await mineNBlock(99);

      const pendingUGOV2 = await masterChefV2.pendingUGOV(tokensID[0]);

      // as we have a new deposit for the same amount/duration
      // we have now only 50% of the shares
      // we should get half the rewards per block
      const calculatedPendingUGOVAfterTheSecondDeposit = uGOVPerBlock.mul(uGOVmultiplier).div(2).mul(99).div(one);
      // we have accumulated UBQ before the second deposit
      // 1 block + 2 blocks for the deposit including the approve and the deposit itself
      const calculatedPendingUGOV2 = calculatedPendingUGOVAfterTheSecondDeposit.add(pendingUGOV).add(pendingUGOV).add(pendingUGOV);
      const isPrecise2 = isAmountEquivalent(pendingUGOV2.toString(), calculatedPendingUGOV2.toString(), "0.00000000001");
      expect(isPrecise2).to.be.true;
      // the rewards is actually what has been calculated
      await masterChefV2.connect(secondAccount).getRewards(tokensID[0]);
      const calculatedPendingUGOVAfterGetRewards = uGOVPerBlock.mul(uGOVmultiplier).div(2).mul(100).div(one).add(pendingUGOV).add(pendingUGOV).add(pendingUGOV);
      const afterBal = await uGOV.balanceOf(secondAddress);
      const isPrecise3 = isAmountEquivalent(afterBal.toString(), calculatedPendingUGOVAfterGetRewards.toString(), "0.00000000001");
      expect(isPrecise3).to.be.true;
    });
  });
});
