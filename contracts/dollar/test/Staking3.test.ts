import { expect } from "chai";
import { Signer, BigNumber, ethers } from "ethers";
import { StakingShare } from "../artifacts/types/StakingShare";
import { stakingSetup, deposit, withdraw } from "./StakingSetup";
import { mineNBlock } from "./utils/hardhatNode";
import { IMetaPool } from "../artifacts/types/IMetaPool";
import { calcShareInToken, isAmountEquivalent } from "./utils/calc";
import { Staking } from "../artifacts/types/Staking";

describe("Staking3", () => {
  const one: BigNumber = BigNumber.from(10).pow(18);

  let admin: Signer;
  let secondAccount: Signer;
  let secondAddress: string;
  let stakingShare: StakingShare;
  let staking: Staking;
  let metaPool: IMetaPool;
  let blockCountInAWeek: BigNumber;

  before(async () => {
    ({
      admin,
      secondAccount,
      stakingShare,
      staking,
      metaPool,
      blockCountInAWeek,
    } = await stakingSetup());
    secondAddress = await secondAccount.getAddress();
  });

  describe("Staking time and redeem", () => {
    let idSecond: number;

    it("second account should be able to bound for 1 weeks", async () => {
      await metaPool.balanceOf(secondAddress);
      idSecond = (await deposit(secondAccount, one.mul(100), 1)).id;

      const bond: BigNumber = await stakingShare.balanceOf(
        secondAddress,
        idSecond
      );
      const isPrecise = isAmountEquivalent(
        bond.toString(),
        "100100000000000000000",
        "0.00000000000000000001"
      );
      expect(isPrecise).to.be.true;
    });
    it("second account should not be able to redeem before 1 week", async () => {
      await expect(withdraw(secondAccount, idSecond)).to.be.revertedWith(
        "Staking: Redeem not allowed before staking time"
      );
    });

    it("second account should be able to redeem after 1 week", async () => {
      const secondAccountAdr = await secondAccount.getAddress();
      const balBSBefore = await stakingShare.balanceOf(
        secondAccountAdr,
        idSecond
      );
      expect(balBSBefore).to.be.equal(
        ethers.utils.parseEther("100.099999999999999999")
      );
      const totalSupplyBSBefore = await stakingShare.totalSupply();
      const TotalLPInStakingBefore = await metaPool.balanceOf(staking.address);
      const balLPBefore = await metaPool.balanceOf(secondAccountAdr);
      expect(balLPBefore).to.be.equal(ethers.utils.parseEther("900"));
      await mineNBlock(blockCountInAWeek.toNumber());
      await withdraw(secondAccount, idSecond);

      const TotalLPInStakingAfter = await metaPool.balanceOf(staking.address);
      const totalSupplyBSAfter = await stakingShare.totalSupply();
      const balLPAfter = await metaPool.balanceOf(secondAccountAdr);
      const balBSAfter = await stakingShare.balanceOf(
        secondAccountAdr,
        idSecond
      );
      const calculatedLPToWithdraw = calcShareInToken(
        totalSupplyBSBefore.toString(),
        balBSBefore.toString(),
        TotalLPInStakingBefore.toString()
      );
      expect(balBSAfter).to.be.equal(0);
      const lpWithdrawn = balLPAfter.sub(balLPBefore);
      const isPrecise = isAmountEquivalent(
        lpWithdrawn.toString(),
        calculatedLPToWithdraw.toString(),
        "0.000000000000000001"
      );
      expect(isPrecise).to.be.true;
      expect(TotalLPInStakingBefore).to.equal(
        TotalLPInStakingAfter.add(lpWithdrawn)
      );
      expect(totalSupplyBSAfter).to.equal(totalSupplyBSBefore.sub(balBSBefore));
    });

    it("admin and second account should be able to bound on same block", async () => {
      const secondAccountAdr = await secondAccount.getAddress();
      const adminAdr = await admin.getAddress();
      const totalSupplyBSBefore = await stakingShare.totalSupply();
      const TotalLPInStakingBefore = await metaPool.balanceOf(staking.address);
      const [bondAdmin, bondSecond] = await Promise.all([
        deposit(admin, one.mul(100), 1),
        deposit(secondAccount, one.mul(100), 1),
      ]);
      const TotalLPInStakingAfter = await metaPool.balanceOf(staking.address);
      expect(TotalLPInStakingAfter).to.equal(
        TotalLPInStakingBefore.add(one.mul(200))
      );
      const { id } = bondAdmin;
      expect(bondAdmin.id).to.be.equal(bondSecond.id);
      const secAccBalBS = await stakingShare.balanceOf(secondAccountAdr, id);
      const adminBalBS = await stakingShare.balanceOf(adminAdr, id);

      const totalSupplyBSAfter = await stakingShare.totalSupply();
      expect(totalSupplyBSAfter).to.equal(
        totalSupplyBSBefore.add(secAccBalBS).add(adminBalBS)
      );
    });
  });
});
