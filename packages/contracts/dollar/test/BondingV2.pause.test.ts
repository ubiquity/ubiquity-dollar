// Should test Pause for BondingV2 and BondingShareV2

import { expect } from "chai";
import { ethers, Signer, BigNumber } from "ethers";
import { IMetaPool } from "../artifacts/types/IMetaPool";
import { BondingV2 } from "../artifacts/types/BondingV2";
import { BondingShareV2 } from "../artifacts/types/BondingShareV2";
import { bondingSetupV2 } from "./BondingSetupV2";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";
import { mineNBlock, resetFork } from "./utils/hardhatNode";

let bondingV2: BondingV2;
let metaPool: IMetaPool;
let bondingShareV2: BondingShareV2;
let admin: Signer;
let secondAccount: Signer;
let bondingMaxAccount: Signer;
let manager: UbiquityAlgorithmicDollarManager;
let blockCountInAWeek: BigNumber;
let adminAddress: string;
let secondAccountAddress: string;

const PAUSER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("PAUSER_ROLE"));

describe("Pause V2 Bonding", () => {
  after(async () => {
    await resetFork(12592661);
  });
  beforeEach(async () => {
    ({ manager, admin, secondAccount, bondingMaxAccount, bondingV2, metaPool, bondingShareV2, blockCountInAWeek } = await bondingSetupV2());
    secondAccountAddress = await secondAccount.getAddress();
    adminAddress = await admin.getAddress();
  });

  describe("Pausing BondingV2", () => {
    it("Should pause and unpause only with role", async () => {
      // pause revert without role
      await expect(bondingV2.connect(secondAccount).pause()).to.be.revertedWith("not pauser");

      // pause work with role
      await expect(bondingV2.connect(admin).pause()).to.not.be.reverted;

      // pause revert if already paused
      await expect(bondingV2.connect(admin).pause()).to.be.revertedWith("Pausable: paused");

      // unpause revert without role
      await expect(bondingV2.connect(secondAccount).unpause()).to.be.revertedWith("not pauser");

      // unpause work with role
      await expect(bondingV2.connect(admin).unpause()).to.not.be.reverted;

      // unpause revert if not paused
      await expect(bondingV2.connect(admin).unpause()).to.be.revertedWith("Pausable: not paused");

      // setting role to pause and unpause
      await manager.connect(admin).grantRole(PAUSER_ROLE, secondAccountAddress);
      await expect(bondingV2.connect(secondAccount).pause()).to.not.be.reverted;
      await expect(bondingV2.connect(secondAccount).unpause()).to.not.be.reverted;
    });

    it("Should pause deposit, addLiquidity and removeLiquidity", async () => {
      const amount = BigNumber.from(1);

      // approve bondingV2 to deposit
      await metaPool.connect(secondAccount).approve(bondingV2.address, amount.mul(2));

      // pause bondingV2 then deposit should fail
      await bondingV2.connect(admin).pause();
      await expect(bondingV2.connect(secondAccount).deposit(amount, 1)).to.be.revertedWith("Pausable: paused");

      // unpause bondingV2 then deposit should work
      await bondingV2.connect(admin).unpause();
      await expect(bondingV2.connect(secondAccount).deposit(amount, 1)).to.not.be.reverted;

      const bondId = await bondingShareV2.totalSupply();

      // wait 1 week to add liquidity
      await mineNBlock(blockCountInAWeek.toNumber());

      // unpause bondingV2 then addLiquidity should fail
      await bondingV2.connect(admin).pause();
      await expect(bondingV2.connect(secondAccount).addLiquidity(bondId, amount, 1)).to.be.revertedWith("Pausable: paused");

      // unpause bondingV2 then addLiquidity should work
      await bondingV2.connect(admin).unpause();
      await expect(bondingV2.connect(secondAccount).addLiquidity(bondId, amount, 1)).to.not.be.reverted;

      // wait 1 week to removeLiquidity
      await mineNBlock(blockCountInAWeek.toNumber());

      // unpause bondingV2 then removeLiquidity should fail
      await bondingV2.connect(admin).pause();
      await expect(bondingV2.connect(secondAccount).removeLiquidity(bondId, amount)).to.be.revertedWith("Pausable: paused");

      // unpause bondingV2 then removeLiquidity should work
      await bondingV2.connect(admin).unpause();
      await expect(bondingV2.connect(secondAccount).removeLiquidity(bondId, amount)).to.not.be.reverted;
    });
  });

  describe("Pausing BondingShareV2", () => {
    it("Should pause and unpause only with role", async () => {
      // pause revert without role
      await expect(bondingShareV2.connect(secondAccount).pause()).to.be.revertedWith("not pauser");

      // pause work with role
      await expect(bondingShareV2.connect(admin).pause()).to.not.be.reverted;

      // pause revert if already paused
      await expect(bondingShareV2.connect(admin).pause()).to.be.revertedWith("Pausable: paused");

      // unpause revert without role
      await expect(bondingShareV2.connect(secondAccount).unpause()).to.be.revertedWith("not pauser");

      // unpause work with role
      await expect(bondingShareV2.connect(admin).unpause()).to.not.be.reverted;

      // unpause revert if not paused
      await expect(bondingShareV2.connect(admin).unpause()).to.be.revertedWith("Pausable: not paused");

      // setting role to pause and unpause
      await manager.connect(admin).grantRole(PAUSER_ROLE, secondAccountAddress);
      await expect(bondingShareV2.connect(secondAccount).pause()).to.not.be.reverted;
      await expect(bondingShareV2.connect(secondAccount).unpause()).to.not.be.reverted;
    });

    it("Should pause updateBond, mint, safeTransferFrom and safeBatchTransferFrom", async () => {
      // pause bondingShareV2 then updateBond should fail
      await bondingShareV2.connect(admin).pause();
      await expect(bondingShareV2.connect(admin).updateBond(1, 1, 1, 1)).to.be.revertedWith("Pausable: paused");

      await expect(bondingShareV2.connect(admin).mint(secondAccountAddress, 1, 1, 1)).to.be.revertedWith("Pausable: paused");

      await expect(bondingShareV2.connect(admin).safeTransferFrom(adminAddress, secondAccountAddress, 1, 1, [])).to.be.revertedWith("Pausable: paused");

      await expect(bondingShareV2.connect(admin).safeBatchTransferFrom(adminAddress, secondAccountAddress, [1, 2], [1, 1], [])).to.be.revertedWith(
        "Pausable: paused"
      );
    });
  });

  describe("Pausing BondingV2 and BondingShareV2", () => {
    it("Should not pause BondingV2 pendingLpRewards, lpRewardForShares, currentShareValue and sendDust", async () => {
      await bondingV2.connect(admin).pause();
      await bondingShareV2.connect(admin).pause();

      await expect(bondingV2.connect(secondAccount).pendingLpRewards(1)).to.not.be.reverted;

      await expect(bondingV2.connect(secondAccount).lpRewardForShares(1, 1)).to.not.be.reverted;

      await expect(bondingV2.connect(secondAccount).currentShareValue()).to.not.be.reverted;

      await expect(bondingV2.connect(admin).sendDust(secondAccountAddress, metaPool.address, 1)).to.not.be.reverted;
    });

    it("Should pause BondingV2 migrate", async () => {
      // approve bondingV2 to deposit
      await metaPool.connect(secondAccount).approve(bondingV2.address, BigNumber.from(10));
      await bondingV2.connect(secondAccount).deposit(BigNumber.from(2), 1);

      await bondingV2.connect(admin).pause();
      await bondingShareV2.connect(admin).pause();

      await expect(bondingV2.connect(bondingMaxAccount).migrate()).to.be.revertedWith("Pausable: paused");
    });
  });
});
