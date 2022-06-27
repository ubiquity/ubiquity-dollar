import { describe, it } from "mocha";
import { BigNumber, Signer } from "ethers";
import { expect } from "./setup";
import { stakingSetupV2, deposit } from "./StakingSetupV2";
import { MasterChefV2 } from "../artifacts/types/MasterChefV2";
import { IMetaPool } from "../artifacts/types/IMetaPool";
import { mineNBlock } from "./utils/hardhatNode";
import { isAmountEquivalent } from "./utils/calc";
import { UbiquityGovernance } from "../artifacts/types/UbiquityGovernance";
import { StakingV2 } from "../artifacts/types/StakingV2";
import { StakingShareV2 } from "../artifacts/types/StakingShareV2";

describe("MasterChefV2", () => {
  const one: BigNumber = BigNumber.from(10).pow(18); // one = 1 ether = 10^18
  let masterChefV2: MasterChefV2;

  let secondAccount: Signer;
  let fourthAccount: Signer;
  let secondAddress: string;
  let metaPool: IMetaPool;
  let uGOV: UbiquityGovernance;
  let stakingV2: StakingV2;
  let stakingShareV2: StakingShareV2;

  beforeEach(async () => {
    ({
      masterChefV2,
      stakingV2,
      stakingShareV2,
      uGOV,
      secondAccount,
      fourthAccount,
      metaPool,
    } = await stakingSetupV2());
    secondAddress = await secondAccount.getAddress();
    // for testing purposes set the week equal to one block
    await stakingV2.setBlockCountInAWeek(1);
  });

  describe("deposit", () => {
    it("should be able to calculate pending UBQ", async () => {
      const totalLPBeforeAdd = await stakingShareV2.totalLP();
      const balanceStakingBeforeAdd = await metaPool.balanceOf(
        stakingV2.address
      );
      const amount = one.mul(100);
      const { id, bsAmount, shares, creationBlock, endBlock } = await deposit(
        secondAccount,
        amount,
        1
      );
      const totalLPAfterAdd = await stakingShareV2.totalLP();
      const balanceStakingAfterAdd = await metaPool.balanceOf(
        stakingV2.address
      );
      expect(totalLPAfterAdd).to.equal(totalLPBeforeAdd.add(amount));
      expect(balanceStakingAfterAdd).to.equal(
        balanceStakingBeforeAdd.add(amount)
      );
      expect(id).to.equal(1);
      expect(bsAmount).to.equal(1);
      const detail = await stakingShareV2.getBond(id);
      expect(detail.lpAmount).to.equal(amount);
      expect(detail.lpFirstDeposited).to.equal(amount);
      expect(detail.minter).to.equal(await secondAccount.getAddress());
      expect(detail.lpRewardDebt).to.equal(0);
      expect(detail.creationBlock).to.equal(creationBlock);
      expect(detail.endBlock).to.equal(endBlock);
      const shareDetail = await masterChefV2.getStakingShareInfo(id);
      expect(shareDetail[0]).to.equal(shares);
      let totShares = await masterChefV2.totalShares();
      let percentage = shareDetail[0].mul(100).div(totShares);
      expect(percentage).to.equal(100);
      // user amount is equal to the amount of user's staking share
      const tokensID = await stakingShareV2.holderTokens(secondAddress);

      // do not have pending rewards just after depositing
      let pendingUGOV = await masterChefV2.pendingUGOV(tokensID[0]);
      expect(pendingUGOV).to.equal(0);

      // as we have 100% of the shares we should get all the rewards per block
      await mineNBlock(1);
      const uGOVPerBlock = await masterChefV2.uGOVPerBlock();
      const uGOVmultiplier = await masterChefV2.uGOVmultiplier();
      pendingUGOV = await masterChefV2.pendingUGOV(tokensID[0]);
      const calculatedPendingUGOV = uGOVPerBlock.mul(uGOVmultiplier).div(one);

      const isPrecise = isAmountEquivalent(
        pendingUGOV.toString(),
        calculatedPendingUGOV.toString(),
        "0.00000000001"
      );
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
      const calculatedPendingUGOVAfterTheSecondDeposit = uGOVPerBlock
        .mul(uGOVmultiplier)
        .div(2)
        .mul(99)
        .div(one);
      // we have accumulated UBQ before the second deposit
      // 1 block + 2 blocks for the deposit including the approve and the deposit itself
      const calculatedPendingUGOV2 = calculatedPendingUGOVAfterTheSecondDeposit
        .add(pendingUGOV)
        .add(pendingUGOV)
        .add(pendingUGOV);
      const isPrecise2 = isAmountEquivalent(
        pendingUGOV2.toString(),
        calculatedPendingUGOV2.toString(),
        "0.00000000001"
      );
      expect(isPrecise2).to.be.true;
      // the rewards is actually what has been calculated
      await masterChefV2.connect(secondAccount).getRewards(tokensID[0]);
      const calculatedPendingUGOVAfterGetRewards = uGOVPerBlock
        .mul(uGOVmultiplier)
        .div(2)
        .mul(100)
        .div(one)
        .add(pendingUGOV)
        .add(pendingUGOV)
        .add(pendingUGOV);
      const afterBal = await uGOV.balanceOf(secondAddress);
      const isPrecise3 = isAmountEquivalent(
        afterBal.toString(),
        calculatedPendingUGOVAfterGetRewards.toString(),
        "0.00000000001"
      );
      expect(isPrecise3).to.be.true;
    });
  });
});
