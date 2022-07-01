// Should test Pause for StakingV2 and StakingShareV2

import { expect } from "chai";
import { ethers, Signer, BigNumber } from "ethers";
import { IMetaPool } from "../artifacts/types/IMetaPool";
import { StakingV2 } from "../artifacts/types/StakingV2";
import { StakingShareV2 } from "../artifacts/types/StakingShareV2";
import { stakingSetupV2 } from "./StakingSetupV2";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";
import { mineNBlock, resetFork } from "./utils/hardhatNode";

let stakingV2: StakingV2;
let metaPool: IMetaPool;
let stakingShareV2: StakingShareV2;
let admin: Signer;
let secondAccount: Signer;
let stakingMaxAccount: Signer;
let manager: UbiquityAlgorithmicDollarManager;
let blockCountInAWeek: BigNumber;
let adminAddress: string;
let secondAccountAddress: string;

const PAUSER_ROLE = ethers.utils.keccak256(
  ethers.utils.toUtf8Bytes("PAUSER_ROLE")
);

describe("Pause V2 Staking", () => {
  after(async () => {
    await resetFork(12592661);
  });
  beforeEach(async () => {
    ({
      manager,
      admin,
      secondAccount,
      stakingMaxAccount,
      stakingV2,
      metaPool,
      stakingShareV2,
      blockCountInAWeek,
    } = await stakingSetupV2());
    secondAccountAddress = await secondAccount.getAddress();
    adminAddress = await admin.getAddress();
  });

  describe("Pausing StakingV2", () => {
    it("Should pause and unpause only with role", async () => {
      // pause revert without role
      await expect(stakingV2.connect(secondAccount).pause()).to.be.revertedWith(
        "not pauser"
      );

      // pause work with role
      await expect(stakingV2.connect(admin).pause()).to.not.be.reverted;

      // pause revert if already paused
      await expect(stakingV2.connect(admin).pause()).to.be.revertedWith(
        "Pausable: paused"
      );

      // unpause revert without role
      await expect(
        stakingV2.connect(secondAccount).unpause()
      ).to.be.revertedWith("not pauser");

      // unpause work with role
      await expect(stakingV2.connect(admin).unpause()).to.not.be.reverted;

      // unpause revert if not paused
      await expect(stakingV2.connect(admin).unpause()).to.be.revertedWith(
        "Pausable: not paused"
      );

      // setting role to pause and unpause
      await manager.connect(admin).grantRole(PAUSER_ROLE, secondAccountAddress);
      await expect(stakingV2.connect(secondAccount).pause()).to.not.be.reverted;
      await expect(stakingV2.connect(secondAccount).unpause()).to.not.be
        .reverted;
    });

    it("Should pause deposit, addLiquidity and removeLiquidity", async () => {
      const amount = BigNumber.from(1);

      // approve stakingV2 to deposit
      await metaPool
        .connect(secondAccount)
        .approve(stakingV2.address, amount.mul(2));

      // pause stakingV2 then deposit should fail
      await stakingV2.connect(admin).pause();
      await expect(
        stakingV2.connect(secondAccount).deposit(amount, 1)
      ).to.be.revertedWith("Pausable: paused");

      // unpause stakingV2 then deposit should work
      await stakingV2.connect(admin).unpause();
      await expect(stakingV2.connect(secondAccount).deposit(amount, 1)).to.not
        .be.reverted;

      const bondId = await stakingShareV2.totalSupply();

      // wait 1 week to add liquidity
      await mineNBlock(blockCountInAWeek.toNumber());

      // unpause stakingV2 then addLiquidity should fail
      await stakingV2.connect(admin).pause();
      await expect(
        stakingV2.connect(secondAccount).addLiquidity(bondId, amount, 1)
      ).to.be.revertedWith("Pausable: paused");

      // unpause stakingV2 then addLiquidity should work
      await stakingV2.connect(admin).unpause();
      await expect(
        stakingV2.connect(secondAccount).addLiquidity(bondId, amount, 1)
      ).to.not.be.reverted;

      // wait 1 week to removeLiquidity
      await mineNBlock(blockCountInAWeek.toNumber());

      // unpause stakingV2 then removeLiquidity should fail
      await stakingV2.connect(admin).pause();
      await expect(
        stakingV2.connect(secondAccount).removeLiquidity(bondId, amount)
      ).to.be.revertedWith("Pausable: paused");

      // unpause stakingV2 then removeLiquidity should work
      await stakingV2.connect(admin).unpause();
      await expect(
        stakingV2.connect(secondAccount).removeLiquidity(bondId, amount)
      ).to.not.be.reverted;
    });
  });

  describe("Pausing StakingShareV2", () => {
    it("Should pause and unpause only with role", async () => {
      // pause revert without role
      await expect(
        stakingShareV2.connect(secondAccount).pause()
      ).to.be.revertedWith("not pauser");

      // pause work with role
      await expect(stakingShareV2.connect(admin).pause()).to.not.be.reverted;

      // pause revert if already paused
      await expect(stakingShareV2.connect(admin).pause()).to.be.revertedWith(
        "Pausable: paused"
      );

      // unpause revert without role
      await expect(
        stakingShareV2.connect(secondAccount).unpause()
      ).to.be.revertedWith("not pauser");

      // unpause work with role
      await expect(stakingShareV2.connect(admin).unpause()).to.not.be.reverted;

      // unpause revert if not paused
      await expect(stakingShareV2.connect(admin).unpause()).to.be.revertedWith(
        "Pausable: not paused"
      );

      // setting role to pause and unpause
      await manager.connect(admin).grantRole(PAUSER_ROLE, secondAccountAddress);
      await expect(stakingShareV2.connect(secondAccount).pause()).to.not.be
        .reverted;
      await expect(stakingShareV2.connect(secondAccount).unpause()).to.not.be
        .reverted;
    });

    it("Should pause updateBond, mint, safeTransferFrom and safeBatchTransferFrom", async () => {
      // pause stakingShareV2 then updateBond should fail
      await stakingShareV2.connect(admin).pause();
      await expect(
        stakingShareV2.connect(admin).updateBond(1, 1, 1, 1)
      ).to.be.revertedWith("Pausable: paused");

      await expect(
        stakingShareV2.connect(admin).mint(secondAccountAddress, 1, 1, 1)
      ).to.be.revertedWith("Pausable: paused");

      await expect(
        stakingShareV2
          .connect(admin)
          .safeTransferFrom(adminAddress, secondAccountAddress, 1, 1, [])
      ).to.be.revertedWith("Pausable: paused");

      await expect(
        stakingShareV2
          .connect(admin)
          .safeBatchTransferFrom(
            adminAddress,
            secondAccountAddress,
            [1, 2],
            [1, 1],
            []
          )
      ).to.be.revertedWith("Pausable: paused");
    });
  });

  describe("Pausing StakingV2 and StakingShareV2", () => {
    it("Should not pause StakingV2 pendingLpRewards, lpRewardForShares, currentShareValue and sendDust", async () => {
      await stakingV2.connect(admin).pause();
      await stakingShareV2.connect(admin).pause();

      await expect(stakingV2.connect(secondAccount).pendingLpRewards(1)).to.not
        .be.reverted;

      await expect(stakingV2.connect(secondAccount).lpRewardForShares(1, 1)).to
        .not.be.reverted;

      await expect(stakingV2.connect(secondAccount).currentShareValue()).to.not
        .be.reverted;

      await expect(
        stakingV2
          .connect(admin)
          .sendDust(secondAccountAddress, metaPool.address, 1)
      ).to.not.be.reverted;
    });

    it("Should pause StakingV2 migrate", async () => {
      // approve stakingV2 to deposit
      await metaPool
        .connect(secondAccount)
        .approve(stakingV2.address, BigNumber.from(10));
      await stakingV2.connect(secondAccount).deposit(BigNumber.from(2), 1);

      await stakingV2.connect(admin).pause();
      await stakingShareV2.connect(admin).pause();

      await expect(
        stakingV2.connect(stakingMaxAccount).migrate()
      ).to.be.revertedWith("Pausable: paused");
    });
  });
});
