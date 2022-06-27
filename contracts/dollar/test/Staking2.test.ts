import { expect } from "chai";
import { Signer, BigNumber, ethers } from "ethers";
import { StakingShare } from "../artifacts/types/StakingShare";
import { IMetaPool } from "../artifacts/types/IMetaPool";
import { Staking } from "../artifacts/types/Staking";
import { stakingSetup, deposit, withdraw } from "./StakingSetup";
import { mineNBlock } from "./utils/hardhatNode";
import { calcShareInToken, isAmountEquivalent } from "./utils/calc";

describe("Staking2", () => {
  let idAdmin: number;
  let idSecond: number;
  const one: BigNumber = BigNumber.from(10).pow(18);

  let metaPool: IMetaPool;
  let staking: Staking;
  let stakingShare: StakingShare;
  let admin: Signer;
  let secondAccount: Signer;
  let thirdAccount: Signer;
  let adminAddress: string;
  let secondAddress: string;
  let thirdAddress: string;
  let blockCountInAWeek: BigNumber;

  before(async () => {
    ({
      admin,
      secondAccount,
      thirdAccount,
      metaPool,
      staking,
      stakingShare,
      blockCountInAWeek,
    } = await stakingSetup());
    adminAddress = await admin.getAddress();
    secondAddress = await secondAccount.getAddress();
    thirdAddress = await thirdAccount.getAddress();
  });
  describe("Staking and Redeem", () => {
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

    it("total uLP of staking contract should start at 100", async () => {
      const bal = await metaPool.balanceOf(staking.address);
      expect(bal).to.be.equal(one.mul(100));
    });

    it("total uBOND should be 0", async () => {
      const totalUBOND = await stakingShare.totalSupply();
      expect(totalUBOND).to.be.equal(0);
    });

    it("admin should be able to bound", async () => {
      const { id, bond } = await deposit(admin, one.mul(100), 1);
      idAdmin = id;
      expect(bond).to.equal(ethers.utils.parseEther("100.099999999999999999"));
      const bondIds = await stakingShare.holderTokens(await admin.getAddress());
      expect(id).to.equal(bondIds[0]);
    });

    it("total uBOND should be 100.01", async () => {
      const totalUBOND: BigNumber = await stakingShare.totalSupply();
      expect(totalUBOND).to.equal(
        ethers.utils.parseEther("100.099999999999999999")
      );
    });

    it("second account should be able to bound", async () => {
      const { id, bond } = await deposit(secondAccount, one.mul(100), 1);
      idSecond = id;
      expect(bond).to.equal(ethers.utils.parseEther("100.099999999999999999"));
      const bondIds = await stakingShare.holderTokens(
        await secondAccount.getAddress()
      );
      expect(id).to.equal(bondIds[0]);
    });

    it("third account should not be able to bound with no LP token", async () => {
      const bal = await metaPool.balanceOf(await thirdAccount.getAddress());
      expect(bal).to.equal(0);
      await expect(
        deposit(thirdAccount, BigNumber.from(1), 1)
      ).to.be.revertedWith("SafeERC20: low-level call failed");
    });

    it("total uLP should be 300", async () => {
      const totalLP: BigNumber = await metaPool.balanceOf(staking.address);
      expect(totalLP).to.be.equal(one.mul(300));
    });

    it("total uBOND should be equal to the sum of the share minted", async () => {
      const totalUBOND: BigNumber = await stakingShare.totalSupply();
      const balSecond = await stakingShare.balanceOf(
        await secondAccount.getAddress(),
        idSecond
      );
      const balAdmin = await stakingShare.balanceOf(
        await admin.getAddress(),
        idAdmin
      );

      expect(totalUBOND).to.equal(balSecond.add(balAdmin));
      expect(totalUBOND).to.be.gt(one.mul(200));
    });

    it("admin account should be able to redeem uBOND", async () => {
      await mineNBlock(blockCountInAWeek.toNumber());
      const balBSBefore = await stakingShare.balanceOf(adminAddress, idAdmin);
      expect(balBSBefore).to.be.equal(
        ethers.utils.parseEther("100.099999999999999999")
      );
      const totalSupplyBSBefore = await stakingShare.totalSupply();
      const TotalLPInStakingBefore = await metaPool.balanceOf(staking.address);
      const balLPBefore = await metaPool.balanceOf(adminAddress);
      expect(balLPBefore).to.be.equal(
        ethers.utils.parseEther("18974.979391392984888116")
      );
      await withdraw(admin, idAdmin);
      const TotalLPInStakingAfter = await metaPool.balanceOf(staking.address);
      const totalSupplyBSAfter = await stakingShare.totalSupply();
      const balLPAfter = await metaPool.balanceOf(adminAddress);
      const balBSAfter = await stakingShare.balanceOf(adminAddress, idAdmin);
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

    it("second account should be able to redeem uBOND", async () => {
      const balBSBefore = await stakingShare.balanceOf(secondAddress, idSecond);
      const totalSupplyBSBefore = await stakingShare.totalSupply();
      const TotalLPInStakingBefore = await metaPool.balanceOf(staking.address);
      const balLPBefore = await metaPool.balanceOf(secondAddress);
      await withdraw(secondAccount, idSecond);
      const TotalLPInStakingAfter = await metaPool.balanceOf(staking.address);
      const totalSupplyBSAfter = await stakingShare.totalSupply();
      const balLPAfter = await metaPool.balanceOf(secondAddress);
      const balBSAfter = await stakingShare.balanceOf(secondAddress, idSecond);
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

    it("third account should be able to redeem uBOND", async () => {
      const balBSBefore = await stakingShare.balanceOf(thirdAddress, idAdmin);
      expect(balBSBefore).to.equal(0);
      const balLPBefore = await metaPool.balanceOf(thirdAddress);
      await withdraw(thirdAccount, idAdmin);
      expect(await stakingShare.balanceOf(thirdAddress, idAdmin)).to.be.equal(
        0
      );
      const balLPAfter = await metaPool.balanceOf(thirdAddress);
      expect(balLPBefore).to.equal(balLPAfter);
    });

    it("total uLP should be 0 after all redeem", async () => {
      const totalLP: BigNumber = await metaPool.balanceOf(staking.address);
      expect(totalLP).to.be.lt(BigNumber.from(10).pow(16));
    });

    it("total uBOND should be 0 after all redeem", async () => {
      const totalUBOND: BigNumber = await stakingShare.totalSupply();
      expect(totalUBOND).to.be.equal(0);
    });
  });
});
