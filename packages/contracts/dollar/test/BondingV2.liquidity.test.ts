import { expect } from "chai";
import { ethers } from "hardhat";
import { Signer, BigNumber } from "ethers";
import { BondingV2 } from "../artifacts/types/BondingV2";
import { BondingShareV2 } from "../artifacts/types/BondingShareV2";
import { bondingSetupV2, deposit, IdBond, addLiquidity, removeLiquidity } from "./BondingSetupV2";
import { latestBlockNumber, mineNBlock } from "./utils/hardhatNode";
import { IMetaPool } from "../artifacts/types/IMetaPool";
import { MasterChefV2 } from "../artifacts/types/MasterChefV2";

describe("bondingV2 liquidity", () => {
  const one: BigNumber = BigNumber.from(10).pow(18); // one = 1 ether = 10^18
  let admin: Signer;
  let secondAccount: Signer;
  let fourthAccount: Signer;
  let metaPool: IMetaPool;
  let bondingV2: BondingV2;
  let bondingShareV2: BondingShareV2;
  let masterChefV2: MasterChefV2;
  let blockCountInAWeek: BigNumber;
  let bond: IdBond;
  let bondFourth: IdBond;
  const amountFourth = one.mul(200);
  let secondAccountAdr: string;
  let fourthAccountAdr: string;
  let bondDetail: {
    minter: string;
    lpFirstDeposited: BigNumber;
    creationBlock: BigNumber;
    lpRewardDebt: BigNumber;
    endBlock: BigNumber;
    lpAmount: BigNumber;
  };
  let bondFourthDetail: {
    minter: string;
    lpFirstDeposited: BigNumber;
    creationBlock: BigNumber;
    lpRewardDebt: BigNumber;
    endBlock: BigNumber;
    lpAmount: BigNumber;
  };

  beforeEach(async () => {
    ({ secondAccount, admin, fourthAccount, metaPool, bondingV2, masterChefV2, bondingShareV2, blockCountInAWeek } = await bondingSetupV2());

    bond = await deposit(secondAccount, one.mul(100), 1);
    secondAccountAdr = await secondAccount.getAddress();
    const bondAmount: BigNumber = await bondingShareV2.balanceOf(secondAccountAdr, bond.id);
    const holderTokens = await bondingShareV2.holderTokens(secondAccountAdr);

    expect(bondAmount).to.equal(1);
    expect(holderTokens.length).to.equal(1);
    expect(holderTokens[0]).to.equal(1);

    bondDetail = await bondingShareV2.getBond(bond.id);

    const shareDetail = await masterChefV2.getBondingShareInfo(bond.id);
    expect(shareDetail[0]).to.equal(bond.shares);

    bondFourth = await deposit(fourthAccount, amountFourth, 42);
    fourthAccountAdr = await fourthAccount.getAddress();
    const bondfAmount: BigNumber = await bondingShareV2.balanceOf(fourthAccountAdr, bondFourth.id);
    const holderTokensFourth = await bondingShareV2.holderTokens(fourthAccountAdr);

    expect(bondfAmount).to.equal(1);
    expect(holderTokensFourth.length).to.equal(1);
    expect(holderTokensFourth[0]).to.equal(2);

    bondFourthDetail = await bondingShareV2.getBond(bondFourth.id);
    const accLpRewardPerShare = await bondingV2.accLpRewardPerShare();
    const debt = bondFourth.shares.mul(accLpRewardPerShare).div(1e12);
    expect(bondFourthDetail.lpRewardDebt).to.equal(debt);
    const shareFourthDetail = await masterChefV2.getBondingShareInfo(bondFourth.id);
    expect(shareFourthDetail[0]).to.equal(bondFourth.shares);
  });

  describe("liquidity", () => {
    it("add should fail if caller is not the bonding share owner", async () => {
      await expect(bondingV2.addLiquidity(1, bond.id, 10)).to.be.revertedWith("Bonding: caller is not owner");
    });
    it("add should fail during locking period", async () => {
      await expect(bondingV2.connect(secondAccount).addLiquidity(1, bond.id, 10)).to.be.revertedWith("Bonding: Redeem not allowed before bonding time");
    });
    it("remove should fail if caller is not the bonding share owner", async () => {
      await expect(bondingV2.removeLiquidity(1, bond.id)).to.be.revertedWith("Bonding: caller is not owner");
    });
    it("remove should fail during locking period", async () => {
      await expect(bondingV2.connect(secondAccount).removeLiquidity(1, bond.id)).to.be.revertedWith("Bonding: Redeem not allowed before bonding time");
    });
    it("add should work", async () => {
      expect(bond.id).to.equal(1);
      expect(bond.bsAmount).to.equal(1);
      expect(bondDetail.lpAmount).to.equal(one.mul(100));
      expect(bondDetail.lpFirstDeposited).to.equal(one.mul(100));
      expect(bondDetail.minter).to.equal(secondAccountAdr);
      expect(bondDetail.lpRewardDebt).to.equal(0);
      expect(bondDetail.creationBlock).to.equal(bond.creationBlock);
      expect(bondDetail.endBlock).to.equal(bond.endBlock);
      expect(bondFourth.id).to.equal(2);
      expect(bondFourth.bsAmount).to.equal(1);
      expect(bondFourthDetail.lpAmount).to.equal(amountFourth);
      expect(bondFourthDetail.lpFirstDeposited).to.equal(amountFourth);
      expect(bondFourthDetail.minter).to.equal(fourthAccountAdr);
      expect(bondFourthDetail.creationBlock).to.equal(bondFourth.creationBlock);
      expect(bondFourthDetail.endBlock).to.equal(bondFourth.endBlock);

      const lastBlockNum = await latestBlockNumber();
      const endOfLockingInBlock = bondDetail.endBlock.toNumber() - lastBlockNum.number;
      const bondBefore = await bondingShareV2.getBond(bond.id);
      await mineNBlock(endOfLockingInBlock);

      const amount = one.mul(900);
      const lastBlock = await latestBlockNumber();

      const totalLPBeforeAdd = await bondingShareV2.totalLP();
      const balanceBondingBeforeAdd = await metaPool.balanceOf(bondingV2.address);
      const pendingLpRewards = await bondingV2.pendingLpRewards(bond.id);
      const bondAfter = await addLiquidity(secondAccount, bond.id, amount, 11);
      const totalLPAfterAdd = await bondingShareV2.totalLP();
      const balanceBondingAfterAdd = await metaPool.balanceOf(bondingV2.address);

      expect(totalLPAfterAdd).to.equal(totalLPBeforeAdd.add(amount).add(pendingLpRewards));
      expect(balanceBondingAfterAdd).to.equal(balanceBondingBeforeAdd.add(amount));

      // lp reward distribution takes place during add or remove liquidity
      // so there should be no more rewards afterwards

      expect(bondAfter.lpFirstDeposited).to.equal(bondBefore.lpFirstDeposited);
      expect(bondAfter.minter).to.equal(bondBefore.minter);
      expect(bondAfter.lpRewardDebt).to.be.gt(bondBefore.lpRewardDebt);
      expect(bondAfter.creationBlock).to.equal(bondBefore.creationBlock);
      expect(bondAfter.endBlock).to.be.gt(bondBefore.endBlock);
      expect(bondAfter.endBlock).to.equal(lastBlock.number + 2 + 11 * blockCountInAWeek.toNumber());
    });
    it("remove should work", async () => {
      expect(bond.id).to.equal(1);
      expect(bond.bsAmount).to.equal(1);
      expect(bondDetail.lpAmount).to.equal(one.mul(100));
      expect(bondDetail.lpFirstDeposited).to.equal(one.mul(100));
      expect(bondDetail.minter).to.equal(secondAccountAdr);
      expect(bondDetail.lpRewardDebt).to.equal(0);
      expect(bondDetail.creationBlock).to.equal(bond.creationBlock);
      expect(bondDetail.endBlock).to.equal(bond.endBlock);
      expect(bondFourth.id).to.equal(2);
      expect(bondFourth.bsAmount).to.equal(1);
      expect(bondFourthDetail.lpAmount).to.equal(amountFourth);
      expect(bondFourthDetail.lpFirstDeposited).to.equal(amountFourth);
      expect(bondFourthDetail.minter).to.equal(fourthAccountAdr);
      expect(bondFourthDetail.creationBlock).to.equal(bondFourth.creationBlock);
      expect(bondFourthDetail.endBlock).to.equal(bondFourth.endBlock);
      const lastBlockNum = await latestBlockNumber();
      const endOfLockingInBlock = bondDetail.endBlock.toNumber() - lastBlockNum.number;
      const bondBefore = await bondingShareV2.getBond(bond.id);
      await mineNBlock(endOfLockingInBlock);
      secondAccountAdr = await secondAccount.getAddress();
      // simulate distribution of lp token to assess the update of lpRewardDebt
      await metaPool.transfer(bondingV2.address, one.mul(10));
      const bondAfter = await removeLiquidity(secondAccount, bond.id, bondDetail.lpAmount.div(2));
      expect(bondAfter.lpFirstDeposited).to.equal(bondBefore.lpFirstDeposited);
      expect(bondAfter.minter).to.equal(bondBefore.minter);
      expect(bondAfter.lpRewardDebt).to.be.gt(bondBefore.lpRewardDebt);
      expect(bondAfter.creationBlock).to.equal(bondBefore.creationBlock);
      expect(bondAfter.endBlock).to.equal(bondBefore.endBlock);
    });
    it("remove all and add again should work", async () => {
      expect(bond.id).to.equal(1);
      expect(bond.bsAmount).to.equal(1);
      expect(bondDetail.lpAmount).to.equal(one.mul(100));
      expect(bondDetail.lpFirstDeposited).to.equal(one.mul(100));
      expect(bondDetail.minter).to.equal(secondAccountAdr);
      expect(bondDetail.lpRewardDebt).to.equal(0);
      expect(bondDetail.creationBlock).to.equal(bond.creationBlock);
      expect(bondDetail.endBlock).to.equal(bond.endBlock);
      expect(bondFourth.id).to.equal(2);
      expect(bondFourth.bsAmount).to.equal(1);
      expect(bondFourthDetail.lpAmount).to.equal(amountFourth);
      expect(bondFourthDetail.lpFirstDeposited).to.equal(amountFourth);
      expect(bondFourthDetail.minter).to.equal(fourthAccountAdr);
      expect(bondFourthDetail.creationBlock).to.equal(bondFourth.creationBlock);
      expect(bondFourthDetail.endBlock).to.equal(bondFourth.endBlock);
      let lastBlockNum = await latestBlockNumber();
      const endOfLockingInBlock = bondDetail.endBlock.toNumber() - lastBlockNum.number;
      const bondBefore = await bondingShareV2.getBond(bond.id);
      await mineNBlock(endOfLockingInBlock);
      secondAccountAdr = await secondAccount.getAddress();

      const totalLPBeforeRemove = await bondingShareV2.totalLP();
      const balanceBondingBeforeRemove = await metaPool.balanceOf(bondingV2.address);
      const pendingLpRewards = await bondingV2.pendingLpRewards(bond.id);
      const bondAfter = await removeLiquidity(secondAccount, bond.id, bondDetail.lpAmount);
      const totalLPAfterRemove = await bondingShareV2.totalLP();
      const balanceBondingAfterRemove = await metaPool.balanceOf(bondingV2.address);
      expect(totalLPAfterRemove).to.equal(totalLPBeforeRemove.sub(bondDetail.lpAmount));
      expect(balanceBondingAfterRemove).to.equal(balanceBondingBeforeRemove.sub(bondDetail.lpAmount).sub(pendingLpRewards));

      expect(bondAfter.lpFirstDeposited).to.equal(bondBefore.lpFirstDeposited);
      expect(bondAfter.minter).to.equal(bondBefore.minter);
      expect(bondAfter.creationBlock).to.equal(bondBefore.creationBlock);
      expect(bondAfter.endBlock).to.equal(bondBefore.endBlock);
      const bsAfter = await masterChefV2.getBondingShareInfo(bond.id);
      expect(bondAfter.lpAmount).to.equal(0);
      expect(bsAfter[0]).to.equal(0);

      // distribute lp rewards through
      // TRANSFER of uLP tokens to bonding contract to simulate excess dollar distribution
      await metaPool.connect(admin).transfer(bondingV2.address, ethers.utils.parseEther("100"));

      const totalLPBeforeAdd = await bondingShareV2.totalLP();
      const balanceBondingBeforeAdd = await metaPool.balanceOf(bondingV2.address);

      const pendingLpRewards2 = await bondingV2.pendingLpRewards(bond.id);
      lastBlockNum = await latestBlockNumber();
      const bond2 = await addLiquidity(secondAccount, bond.id, bondDetail.lpAmount, 408);
      const pendingLpRewardsAfter2 = await bondingV2.pendingLpRewards(bond.id);
      const totalLPAfterAdd = await bondingShareV2.totalLP();
      const balanceBondingAfterAdd = await metaPool.balanceOf(bondingV2.address);
      expect(pendingLpRewardsAfter2).to.equal(0);
      expect(pendingLpRewards2).to.equal(0);
      expect(totalLPAfterAdd).to.equal(totalLPBeforeAdd.add(bondDetail.lpAmount));
      expect(balanceBondingAfterAdd).to.equal(balanceBondingBeforeAdd.add(bondDetail.lpAmount));
      expect(bond2.lpFirstDeposited).to.equal(bondBefore.lpFirstDeposited);
      expect(bond2.minter).to.equal(bondBefore.minter);
      expect(bond2.lpRewardDebt).to.be.gt(bondBefore.lpRewardDebt);
      expect(bond2.creationBlock).to.equal(bondBefore.creationBlock);
      expect(bond2.endBlock).to.be.gt(bondBefore.endBlock);
      expect(bond2.endBlock).to.equal(lastBlockNum.number + 2 + 408 * blockCountInAWeek.toNumber());
    });
  });
});
