import { expect } from "chai";
import { ethers } from "hardhat";
import { Signer, BigNumber } from "ethers";
import { StakingV2 } from "../artifacts/types/StakingV2";
import { StakingShareV2 } from "../artifacts/types/StakingShareV2";
import { UbiquityAlgorithmicDollar } from "../artifacts/types/UbiquityAlgorithmicDollar";
import { DebtCouponManager } from "../artifacts/types/DebtCouponManager";
import { UbiquityAutoRedeem } from "../artifacts/types/UbiquityAutoRedeem";
import { stakingSetupV2, deposit } from "./StakingSetupV2";
import { mineNBlock } from "./utils/hardhatNode";
import { IMetaPool } from "../artifacts/types/IMetaPool";
import { ERC20 } from "../artifacts/types/ERC20";
import { TWAPOracle } from "../artifacts/types/TWAPOracle";
import { MasterChefV2 } from "../artifacts/types/MasterChefV2";
import { swap3CRVtoUAD, swapUADto3CRV } from "./utils/swap";
import { isAmountEquivalent } from "./utils/calc";

describe("stakingV2 deposit", () => {
  const one: BigNumber = BigNumber.from(10).pow(18); // one = 1 ether = 10^18
  let debtCouponMgr: DebtCouponManager;
  let secondAccount: Signer;
  let fourthAccount: Signer;
  let twapOracle: TWAPOracle;
  let uAD: UbiquityAlgorithmicDollar;
  let uAR: UbiquityAutoRedeem;
  let crvToken: ERC20;
  let metaPool: IMetaPool;
  let stakingV2: StakingV2;
  let stakingShareV2: StakingShareV2;
  let masterChefV2: MasterChefV2;
  let blockCountInAWeek: BigNumber;
  beforeEach(async () => {
    ({
      secondAccount,
      fourthAccount,
      uAD,
      metaPool,
      stakingV2,
      masterChefV2,
      debtCouponMgr,
      uAR,
      crvToken,
      stakingShareV2,
      twapOracle,
      blockCountInAWeek,
    } = await stakingSetupV2());
  });

  it("deposit should work", async () => {
    const totalLPBeforeAdd = await stakingShareV2.totalLP();
    const balanceStakingBeforeAdd = await metaPool.balanceOf(stakingV2.address);
    const amount = one.mul(100);
    const { id, bsAmount, shares, creationBlock, endBlock } = await deposit(
      secondAccount,
      amount,
      1
    );
    const totalLPAfterAdd = await stakingShareV2.totalLP();
    const balanceStakingAfterAdd = await metaPool.balanceOf(stakingV2.address);
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
    await mineNBlock(blockCountInAWeek.toNumber());
  });
  describe("pendingLpRewards", () => {
    it("should increase after inflation ", async () => {
      const { id, bsAmount, shares, creationBlock, endBlock } = await deposit(
        secondAccount,
        one.mul(100),
        1
      );
      expect(id).to.equal(1);
      expect(bsAmount).to.equal(1);
      const detail = await stakingShareV2.getBond(id);
      expect(detail.lpAmount).to.equal(one.mul(100));
      expect(detail.lpFirstDeposited).to.equal(one.mul(100));
      expect(detail.minter).to.equal(await secondAccount.getAddress());
      expect(detail.lpRewardDebt).to.equal(0);
      expect(detail.creationBlock).to.equal(creationBlock);
      expect(detail.endBlock).to.equal(endBlock);
      const shareDetail = await masterChefV2.getStakingShareInfo(id);
      expect(shareDetail[0]).to.equal(shares);
      // trigger a debt cycle
      const secondAccountAdr = await secondAccount.getAddress();

      await expect(
        debtCouponMgr.connect(secondAccount).exchangeDollarsForUAR(1)
      )
        .to.emit(uAR, "Transfer")
        .withArgs(ethers.constants.AddressZero, secondAccountAdr, 1);

      let debtCyle = await debtCouponMgr.debtCycle();
      expect(debtCyle).to.be.true;
      // now we should push the price up to trigger the excess dollar minting

      //  await swap3CRVtoUAD(metaPool, crvToken, one.mul(20000), fourthAccount);
      await swap3CRVtoUAD(metaPool, crvToken, one.mul(10000), fourthAccount);
      // await swap3CRVtoUAD(metaPool, crvToken, one.mul(30000), fourthAccount);
      await mineNBlock(blockCountInAWeek.toNumber());
      await swap3CRVtoUAD(metaPool, crvToken, one.mul(100), fourthAccount);
      await twapOracle.update();

      const lpTotalSupply = await metaPool.totalSupply();

      // Price must be below 1 to mint coupons

      const stakingV2BalBefore = await metaPool.balanceOf(stakingV2.address);
      await debtCouponMgr
        .connect(secondAccount)
        .burnAutoRedeemTokensForDollars(1);
      const stakingV2BalAfter = await metaPool.balanceOf(stakingV2.address);

      expect(stakingV2BalAfter).to.be.gt(stakingV2BalBefore);

      debtCyle = await debtCouponMgr.debtCycle();
      expect(debtCyle).to.be.false;
      await twapOracle.update();
      const lpTotalSupplyAfter = await metaPool.totalSupply();
      expect(lpTotalSupplyAfter).to.be.gt(lpTotalSupply);

      const lpRewards = await stakingV2.lpRewards();
      // lprewards has not been updated yet
      expect(lpRewards).to.equal(0);

      const totalLP = await stakingShareV2.totalLP();
      expect(detail.lpAmount).to.equal(totalLP);
      // one BS gets all the shares and LP
      const totalShares = await masterChefV2.totalShares();
      expect(shares).to.equal(totalShares);

      // another deposit should not get some lp rewards
      const ibond2 = await deposit(fourthAccount, one.mul(100), 1);
      expect(ibond2.id).to.equal(2);
      expect(ibond2.bsAmount).to.equal(1);
      const pendingLpRewards1 = await stakingV2.pendingLpRewards(id);
      // now lprewards should have been updated
      const lpRewardsAfter2ndDeposit = await stakingV2.lpRewards();

      // first user should get all the rewards

      const isPrecise = isAmountEquivalent(
        pendingLpRewards1.toString(),
        lpRewardsAfter2ndDeposit.toString(),
        "0.0000000001"
      );
      expect(isPrecise).to.be.true;

      const pendingLpRewards2 = await stakingV2.pendingLpRewards(ibond2.id);
      // second user should get none of the previous rewards
      expect(pendingLpRewards2).to.equal(0);

      const detail2 = await stakingShareV2.getBond(ibond2.id);

      expect(detail2.lpAmount).to.equal(one.mul(100));
      expect(detail2.lpFirstDeposited).to.equal(one.mul(100));
      expect(detail2.minter).to.equal(await fourthAccount.getAddress());
      expect(detail2.lpRewardDebt).to.equal(pendingLpRewards1);
      expect(detail2.creationBlock).to.equal(ibond2.creationBlock);
      expect(detail2.endBlock).to.equal(ibond2.endBlock);

      // lp amount should increase
      const totalLPAfter2ndDeposit = await stakingShareV2.totalLP();
      expect(totalLP.add(detail2.lpAmount)).to.equal(totalLPAfter2ndDeposit);
      // bs shares should increase
      const totalSharesAfter2ndDeposit = await masterChefV2.totalShares();
      expect(totalShares.add(ibond2.shares)).to.equal(
        totalSharesAfter2ndDeposit
      );
    });
    it("should increase only when we deposit after inflation ", async () => {
      const { id, shares } = await deposit(secondAccount, one.mul(100), 1);
      const detail = await stakingShareV2.getBond(id);
      // trigger a debt cycle
      const secondAccountAdr = await secondAccount.getAddress();
      await expect(
        debtCouponMgr.connect(secondAccount).exchangeDollarsForUAR(1)
      )
        .to.emit(uAR, "Transfer")
        .withArgs(ethers.constants.AddressZero, secondAccountAdr, 1);

      // now we should push the price up to trigger the excess dollar minting
      await swap3CRVtoUAD(metaPool, crvToken, one.mul(10000), fourthAccount);
      await mineNBlock(blockCountInAWeek.toNumber());
      await swap3CRVtoUAD(metaPool, crvToken, one.mul(100), fourthAccount);
      await twapOracle.update();

      const lpTotalSupply = await metaPool.totalSupply();

      // Price must be below 1 to mint coupons

      const stakingV2BalBefore = await metaPool.balanceOf(stakingV2.address);
      await debtCouponMgr
        .connect(secondAccount)
        .burnAutoRedeemTokensForDollars(1);
      const stakingV2BalAfter = await metaPool.balanceOf(stakingV2.address);

      expect(stakingV2BalAfter).to.be.gt(stakingV2BalBefore);

      await twapOracle.update();
      const lpTotalSupplyAfter = await metaPool.totalSupply();
      expect(lpTotalSupplyAfter).to.be.gt(lpTotalSupply);

      const lpRewards = await stakingV2.lpRewards();
      // lprewards has not been updated yet
      expect(lpRewards).to.equal(0);

      const totalLP = await stakingShareV2.totalLP();

      expect(detail.lpAmount).to.equal(totalLP);
      // one BS gets all the shares and LP
      const totalShares = await masterChefV2.totalShares();

      expect(shares).to.equal(totalShares);

      // another deposit should not get some lp rewards
      const ibond2 = await deposit(fourthAccount, one.mul(100), 1);
      expect(ibond2.id).to.equal(2);
      expect(ibond2.bsAmount).to.equal(1);

      const pendingLpRewards1 = await stakingV2.pendingLpRewards(id);
      // lprewards should have been updated
      const lpRewardsAfter2ndDeposit = await stakingV2.lpRewards();

      // first user should get all the rewards

      const isPrecise = isAmountEquivalent(
        pendingLpRewards1.toString(),
        lpRewardsAfter2ndDeposit.toString(),
        "0.0000000001"
      );
      expect(isPrecise).to.be.true;

      const pendingLpRewards2 = await stakingV2.pendingLpRewards(ibond2.id);
      // second user should get none of the previous rewards
      expect(pendingLpRewards2).to.equal(0);

      const detail2 = await stakingShareV2.getBond(ibond2.id);

      expect(detail2.lpAmount).to.equal(one.mul(100));
      expect(detail2.lpFirstDeposited).to.equal(one.mul(100));
      expect(detail2.minter).to.equal(await fourthAccount.getAddress());
      expect(detail2.lpRewardDebt).to.equal(pendingLpRewards1);
      expect(detail2.creationBlock).to.equal(ibond2.creationBlock);
      expect(detail2.endBlock).to.equal(ibond2.endBlock);

      // lp amount should increase
      const totalLPAfter2ndDeposit = await stakingShareV2.totalLP();
      expect(totalLP.add(detail2.lpAmount)).to.equal(totalLPAfter2ndDeposit);
      // bs shares should increase
      const totalSharesAfter2ndDeposit = await masterChefV2.totalShares();
      expect(totalShares.add(ibond2.shares)).to.equal(
        totalSharesAfter2ndDeposit
      );
      // trigger another excess dollar distribution
      //   1- push dollar price < 1$
      await swapUADto3CRV(metaPool, uAD, one.mul(10000), fourthAccount);
      await mineNBlock(blockCountInAWeek.toNumber());
      await swapUADto3CRV(metaPool, uAD, one.mul(100), fourthAccount);
      await twapOracle.update();
      //   2- trigger debt cycle
      await debtCouponMgr.connect(secondAccount).exchangeDollarsForUAR(1);

      const debtCyle = await debtCouponMgr.debtCycle();
      expect(debtCyle).to.be.true;
      //   3- push dollar price > 1$

      await swap3CRVtoUAD(metaPool, crvToken, one.mul(30000), fourthAccount);
      await mineNBlock(blockCountInAWeek.toNumber());
      await swap3CRVtoUAD(metaPool, crvToken, one.mul(100), fourthAccount);
      await twapOracle.update();
      //   4- trigger excess dollar distribution
      await debtCouponMgr
        .connect(secondAccount)
        .burnAutoRedeemTokensForDollars(1);
      const stakingV2Bal2After = await metaPool.balanceOf(stakingV2.address);

      expect(stakingV2Bal2After).to.be.gt(stakingV2BalAfter);
      // check that bs1 have increased it lprewards
      const pendingLpRewards1After2ndExcessDollarDistrib =
        await stakingV2.pendingLpRewards(id);
      expect(pendingLpRewards1After2ndExcessDollarDistrib).to.be.gt(
        pendingLpRewards1
      );
      // check that bs2 have increased it lprewards
      const pendingLpRewards2After2ndExcessDollarDistrib =
        await stakingV2.pendingLpRewards(ibond2.id);
      expect(pendingLpRewards2After2ndExcessDollarDistrib).to.be.gt(0);
      expect(pendingLpRewards1After2ndExcessDollarDistrib).to.be.gt(
        pendingLpRewards2After2ndExcessDollarDistrib
      );
      // total share + pending lp rewards + lp to migrate should be almost equal to lp tokens inside the staking contract
      const totalLPToMigrate = await stakingV2.totalLpToMigrate();
      const isPendingLPPrecise = isAmountEquivalent(
        stakingV2Bal2After.toString(),
        totalLPAfter2ndDeposit
          .add(totalLPToMigrate)
          .add(pendingLpRewards1After2ndExcessDollarDistrib)
          .add(pendingLpRewards2After2ndExcessDollarDistrib)
          .toString(),
        "0.0000000001"
      );
      expect(isPendingLPPrecise).to.be.true;
    });
  });
});
