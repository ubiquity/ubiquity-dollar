import { expect } from "chai";
import { Signer, BigNumber, ethers } from "ethers";
import { BondingShare } from "../artifacts/types/BondingShare";
import { IMetaPool } from "../artifacts/types/IMetaPool";
import { Bonding } from "../artifacts/types/Bonding";
import { bondingSetup, deposit, withdraw } from "./BondingSetup";
import { mineNBlock } from "./utils/hardhatNode";
import { calcShareInToken, isAmountEquivalent } from "./utils/calc";

describe("Bonding2", () => {
  let idAdmin: number;
  let idSecond: number;
  const one: BigNumber = BigNumber.from(10).pow(18);

  let metaPool: IMetaPool;
  let bonding: Bonding;
  let bondingShare: BondingShare;
  let admin: Signer;
  let secondAccount: Signer;
  let thirdAccount: Signer;
  let adminAddress: string;
  let secondAddress: string;
  let thirdAddress: string;
  let blockCountInAWeek: BigNumber;

  before(async () => {
    ({ admin, secondAccount, thirdAccount, metaPool, bonding, bondingShare, blockCountInAWeek } = await bondingSetup());
    adminAddress = await admin.getAddress();
    secondAddress = await secondAccount.getAddress();
    thirdAddress = await thirdAccount.getAddress();
  });
  describe("Bonding and Redeem", () => {
    it("admin should have some uLP tokens", async () => {
      const bal = await metaPool.balanceOf(adminAddress);
      expect(bal).to.be.gte(one.mul(1000));
    });

    it("second account should have some uLP tokens", async () => {
      const bal = await metaPool.balanceOf(secondAddress);
      expect(bal).to.be.gte(one.mul(1000));
    });

    it("third account should have no uLP tokens", async () => {
      expect(await metaPool.balanceOf(thirdAddress)).to.be.equal(0);
    });

    it("total uLP of bonding contract should start at 100", async () => {
      const bal = await metaPool.balanceOf(bonding.address);
      expect(bal).to.be.equal(one.mul(100));
    });

    it("total uBOND should be 0", async () => {
      const totalUBOND = await bondingShare.totalSupply();
      expect(totalUBOND).to.be.equal(0);
    });

    it("admin should be able to bound", async () => {
      const { id, bond } = await deposit(admin, one.mul(100), 1);
      idAdmin = id;
      expect(bond).to.equal(ethers.utils.parseEther("100.099999999999999999"));
      const bondIds = await bondingShare.holderTokens(await admin.getAddress());
      expect(id).to.equal(bondIds[0]);
    });

    it("total uBOND should be 100.01", async () => {
      const totalUBOND: BigNumber = await bondingShare.totalSupply();
      expect(totalUBOND).to.equal(ethers.utils.parseEther("100.099999999999999999"));
    });

    it("second account should be able to bound", async () => {
      const { id, bond } = await deposit(secondAccount, one.mul(100), 1);
      idSecond = id;
      expect(bond).to.equal(ethers.utils.parseEther("100.099999999999999999"));
      const bondIds = await bondingShare.holderTokens(await secondAccount.getAddress());
      expect(id).to.equal(bondIds[0]);
    });

    it("third account should not be able to bound with no LP token", async () => {
      const bal = await metaPool.balanceOf(await thirdAccount.getAddress());
      expect(bal).to.equal(0);
      await expect(deposit(thirdAccount, BigNumber.from(1), 1)).to.be.revertedWith("SafeERC20: low-level call failed");
    });

    it("total uLP should be 300", async () => {
      const totalLP: BigNumber = await metaPool.balanceOf(bonding.address);
      expect(totalLP).to.be.equal(one.mul(300));
    });

    it("total uBOND should be equal to the sum of the share minted", async () => {
      const totalUBOND: BigNumber = await bondingShare.totalSupply();
      const balSecond = await bondingShare.balanceOf(await secondAccount.getAddress(), idSecond);
      const balAdmin = await bondingShare.balanceOf(await admin.getAddress(), idAdmin);

      expect(totalUBOND).to.equal(balSecond.add(balAdmin));
      expect(totalUBOND).to.be.gt(one.mul(200));
    });

    it("admin account should be able to redeem uBOND", async () => {
      await mineNBlock(blockCountInAWeek.toNumber());
      const balBSBefore = await bondingShare.balanceOf(adminAddress, idAdmin);
      expect(balBSBefore).to.be.equal(ethers.utils.parseEther("100.099999999999999999"));
      const totalSupplyBSBefore = await bondingShare.totalSupply();
      const TotalLPInBondingBefore = await metaPool.balanceOf(bonding.address);
      const balLPBefore = await metaPool.balanceOf(adminAddress);
      expect(balLPBefore).to.be.equal(ethers.utils.parseEther("18974.979391392984888116"));
      await withdraw(admin, idAdmin);
      const TotalLPInBondingAfter = await metaPool.balanceOf(bonding.address);
      const totalSupplyBSAfter = await bondingShare.totalSupply();
      const balLPAfter = await metaPool.balanceOf(adminAddress);
      const balBSAfter = await bondingShare.balanceOf(adminAddress, idAdmin);
      const calculatedLPToWithdraw = calcShareInToken(totalSupplyBSBefore.toString(), balBSBefore.toString(), TotalLPInBondingBefore.toString());
      expect(balBSAfter).to.be.equal(0);
      const lpWithdrawn = balLPAfter.sub(balLPBefore);
      const isPrecise = isAmountEquivalent(lpWithdrawn.toString(), calculatedLPToWithdraw.toString(), "0.000000000000000001");
      expect(isPrecise).to.be.true;
      expect(TotalLPInBondingBefore).to.equal(TotalLPInBondingAfter.add(lpWithdrawn));
      expect(totalSupplyBSAfter).to.equal(totalSupplyBSBefore.sub(balBSBefore));
    });

    it("second account should be able to redeem uBOND", async () => {
      const balBSBefore = await bondingShare.balanceOf(secondAddress, idSecond);
      const totalSupplyBSBefore = await bondingShare.totalSupply();
      const TotalLPInBondingBefore = await metaPool.balanceOf(bonding.address);
      const balLPBefore = await metaPool.balanceOf(secondAddress);
      await withdraw(secondAccount, idSecond);
      const TotalLPInBondingAfter = await metaPool.balanceOf(bonding.address);
      const totalSupplyBSAfter = await bondingShare.totalSupply();
      const balLPAfter = await metaPool.balanceOf(secondAddress);
      const balBSAfter = await bondingShare.balanceOf(secondAddress, idSecond);
      const calculatedLPToWithdraw = calcShareInToken(totalSupplyBSBefore.toString(), balBSBefore.toString(), TotalLPInBondingBefore.toString());
      expect(balBSAfter).to.be.equal(0);
      const lpWithdrawn = balLPAfter.sub(balLPBefore);
      const isPrecise = isAmountEquivalent(lpWithdrawn.toString(), calculatedLPToWithdraw.toString(), "0.000000000000000001");
      expect(isPrecise).to.be.true;
      expect(TotalLPInBondingBefore).to.equal(TotalLPInBondingAfter.add(lpWithdrawn));
      expect(totalSupplyBSAfter).to.equal(totalSupplyBSBefore.sub(balBSBefore));
    });

    it("third account should be able to redeem uBOND", async () => {
      const balBSBefore = await bondingShare.balanceOf(thirdAddress, idAdmin);
      expect(balBSBefore).to.equal(0);
      const balLPBefore = await metaPool.balanceOf(thirdAddress);
      await withdraw(thirdAccount, idAdmin);
      expect(await bondingShare.balanceOf(thirdAddress, idAdmin)).to.be.equal(0);
      const balLPAfter = await metaPool.balanceOf(thirdAddress);
      expect(balLPBefore).to.equal(balLPAfter);
    });

    it("total uLP should be 0 after all redeem", async () => {
      const totalLP: BigNumber = await metaPool.balanceOf(bonding.address);
      expect(totalLP).to.be.lt(BigNumber.from(10).pow(16));
    });

    it("total uBOND should be 0 after all redeem", async () => {
      const totalUBOND: BigNumber = await bondingShare.totalSupply();
      expect(totalUBOND).to.be.equal(0);
    });
  });
});
