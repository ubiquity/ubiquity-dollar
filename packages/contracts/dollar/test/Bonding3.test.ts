import { expect } from "chai";
import { Signer, BigNumber, ethers } from "ethers";
import { BondingShare } from "../artifacts/types/BondingShare";
import { bondingSetup, deposit, withdraw } from "./BondingSetup";
import { mineNBlock } from "./utils/hardhatNode";
import { IMetaPool } from "../artifacts/types/IMetaPool";
import { calcShareInToken, isAmountEquivalent } from "./utils/calc";
import { Bonding } from "../artifacts/types/Bonding";

describe("Bonding3", () => {
  const one: BigNumber = BigNumber.from(10).pow(18);

  let admin: Signer;
  let secondAccount: Signer;
  let secondAddress: string;
  let bondingShare: BondingShare;
  let bonding: Bonding;
  let metaPool: IMetaPool;
  let blockCountInAWeek: BigNumber;

  before(async () => {
    ({ admin, secondAccount, bondingShare, bonding, metaPool, blockCountInAWeek } = await bondingSetup());
    secondAddress = await secondAccount.getAddress();
  });

  describe("Bonding time and redeem", () => {
    let idSecond: number;

    it("second account should be able to bound for 1 weeks", async () => {
      await metaPool.balanceOf(secondAddress);
      idSecond = (await deposit(secondAccount, one.mul(100), 1)).id;

      const bond: BigNumber = await bondingShare.balanceOf(secondAddress, idSecond);
      const isPrecise = isAmountEquivalent(bond.toString(), "100100000000000000000", "0.00000000000000000001");
      expect(isPrecise).to.be.true;
    });
    it("second account should not be able to redeem before 1 week", async () => {
      await expect(withdraw(secondAccount, idSecond)).to.be.revertedWith("Bonding: Redeem not allowed before bonding time");
    });

    it("second account should be able to redeem after 1 week", async () => {
      const secondAccountAdr = await secondAccount.getAddress();
      const balBSBefore = await bondingShare.balanceOf(secondAccountAdr, idSecond);
      expect(balBSBefore).to.be.equal(ethers.utils.parseEther("100.099999999999999999"));
      const totalSupplyBSBefore = await bondingShare.totalSupply();
      const TotalLPInBondingBefore = await metaPool.balanceOf(bonding.address);
      const balLPBefore = await metaPool.balanceOf(secondAccountAdr);
      expect(balLPBefore).to.be.equal(ethers.utils.parseEther("900"));
      await mineNBlock(blockCountInAWeek.toNumber());
      await withdraw(secondAccount, idSecond);

      const TotalLPInBondingAfter = await metaPool.balanceOf(bonding.address);
      const totalSupplyBSAfter = await bondingShare.totalSupply();
      const balLPAfter = await metaPool.balanceOf(secondAccountAdr);
      const balBSAfter = await bondingShare.balanceOf(secondAccountAdr, idSecond);
      const calculatedLPToWithdraw = calcShareInToken(totalSupplyBSBefore.toString(), balBSBefore.toString(), TotalLPInBondingBefore.toString());
      expect(balBSAfter).to.be.equal(0);
      const lpWithdrawn = balLPAfter.sub(balLPBefore);
      const isPrecise = isAmountEquivalent(lpWithdrawn.toString(), calculatedLPToWithdraw.toString(), "0.000000000000000001");
      expect(isPrecise).to.be.true;
      expect(TotalLPInBondingBefore).to.equal(TotalLPInBondingAfter.add(lpWithdrawn));
      expect(totalSupplyBSAfter).to.equal(totalSupplyBSBefore.sub(balBSBefore));
    });

    it("admin and second account should be able to bound on same block", async () => {
      const secondAccountAdr = await secondAccount.getAddress();
      const adminAdr = await admin.getAddress();
      const totalSupplyBSBefore = await bondingShare.totalSupply();
      const TotalLPInBondingBefore = await metaPool.balanceOf(bonding.address);
      const [bondAdmin, bondSecond] = await Promise.all([deposit(admin, one.mul(100), 1), deposit(secondAccount, one.mul(100), 1)]);
      const TotalLPInBondingAfter = await metaPool.balanceOf(bonding.address);
      expect(TotalLPInBondingAfter).to.equal(TotalLPInBondingBefore.add(one.mul(200)));
      const { id } = bondAdmin;
      expect(bondAdmin.id).to.be.equal(bondSecond.id);
      const secAccBalBS = await bondingShare.balanceOf(secondAccountAdr, id);
      const adminBalBS = await bondingShare.balanceOf(adminAdr, id);

      const totalSupplyBSAfter = await bondingShare.totalSupply();
      expect(totalSupplyBSAfter).to.equal(totalSupplyBSBefore.add(secAccBalBS).add(adminBalBS));
    });
  });
});
