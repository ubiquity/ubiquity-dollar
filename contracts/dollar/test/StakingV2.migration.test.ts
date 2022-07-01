import { expect } from "chai";
import { Signer, BigNumber } from "ethers";
import { StakingV2 } from "../artifacts/types/StakingV2";
import { StakingShareV2 } from "../artifacts/types/StakingShareV2";
import { stakingSetupV2 } from "./StakingSetupV2";
import { IMetaPool } from "../artifacts/types/IMetaPool";
import { isAmountEquivalent } from "./utils/calc";
import { MasterChefV2 } from "../artifacts/types/MasterChefV2";
import { UbiquityFormulas } from "../artifacts/types/UbiquityFormulas";

type Bond = [string, BigNumber, BigNumber, BigNumber, BigNumber, BigNumber] & {
  minter: string;
  lpFirstDeposited: BigNumber;
  creationBlock: BigNumber;
  lpRewardDebt: BigNumber;
  endBlock: BigNumber;
  lpAmount: BigNumber;
};
const one: BigNumber = BigNumber.from(10).pow(18); // one = 1 ether = 10^18
let stakingV2: StakingV2;
let stakingShareV2: StakingShareV2;
let masterChefV2: MasterChefV2;
let secondAccount: Signer;
let ubiquityFormulas: UbiquityFormulas;
let metaPool: IMetaPool;
let stakingMinBalance: BigNumber;
let stakingMaxBalance: BigNumber;
let stakingZeroAccount: Signer;
let stakingMinAccount: Signer;
let stakingMaxAccount: Signer;
let stakingMinAddress: string;
let stakingMaxAddress: string;
let secondAddress: string;
let admin: Signer;

describe("stakingV2 migration", () => {
  beforeEach(async () => {
    ({
      admin,
      secondAccount,
      masterChefV2,
      ubiquityFormulas,
      metaPool,
      stakingV2,
      stakingShareV2,
      stakingZeroAccount,
      stakingMinAccount,
      stakingMinBalance,
      stakingMaxAccount,
      stakingMaxBalance,
    } = await stakingSetupV2());
    secondAddress = await secondAccount.getAddress();
    stakingMinAddress = await stakingMinAccount.getAddress();
    stakingMaxAddress = await stakingMaxAccount.getAddress();
  });
  describe("migrate", () => {
    it("migrate should work", async () => {
      await expect(stakingV2.connect(stakingMaxAccount).migrate()).to.not.be
        .reverted;
    });

    it("migrate should fail second time", async () => {
      await expect(stakingV2.connect(stakingMaxAccount).migrate()).to.not.be
        .reverted;

      await expect(
        stakingV2.connect(stakingMaxAccount).migrate()
      ).to.be.revertedWith("not v1 address");
    });

    it("migrate should fail if msg.sender is not a user to migrate", async () => {
      // second account not v1 => migrate should revert
      await expect(stakingV2.connect(admin).migrate()).to.be.revertedWith(
        "not v1 address"
      );
    });

    it("migrate should fail if not in migration", async () => {
      await stakingV2.connect(admin).setMigrating(false);
      await expect(
        stakingV2.connect(stakingMinAccount).migrate()
      ).to.be.revertedWith("not in migration");

      await stakingV2.connect(admin).setMigrating(true);
      await expect(stakingV2.connect(stakingMinAccount).migrate()).to.not.be
        .reverted;
    });

    it("migrate should fail if user LP amount to migrate is 0", async () => {
      await expect(
        stakingV2.connect(stakingZeroAccount).migrate()
      ).to.be.revertedWith("LP amount is zero");
    });

    it("migrate should raise event", async () => {
      await expect(stakingV2.connect(stakingMinAccount).migrate()).to.emit(
        stakingV2,
        "Migrated"
      );
    });
  });

  describe("addUserToMigrate", () => {
    it("addUserToMigrate should work if migrator", async () => {
      await expect(
        stakingV2.connect(admin).addUserToMigrate(secondAddress, 1, 1)
      ).to.not.be.reverted;
    });

    it("addUserToMigrate should fail if not migrator", async () => {
      await expect(
        stakingV2
          .connect(stakingMaxAccount)
          .addUserToMigrate(secondAddress, 1, 1)
      ).to.be.revertedWith("not migrator");
    });

    it("addUserToMigrate should permit user to migrate", async () => {
      await expect(
        stakingV2.connect(admin).addUserToMigrate(secondAddress, 1, 1)
      ).to.not.be.reverted;

      await expect(stakingV2.connect(secondAccount).migrate()).to.not.be
        .reverted;
    });

    it("addUserToMigrate should give id to user", async () => {
      await stakingV2.connect(admin).addUserToMigrate(secondAddress, 1, 1);

      expect(await stakingV2.toMigrateId(secondAddress)).to.be.gt(1);
    });
  });

  describe("migrating", () => {
    it("migrating should be true if in migration", async () => {
      expect(await stakingV2.migrating()).to.be.true;
    });

    it("migrating should be false if not in migration", async () => {
      await stakingV2.connect(admin).setMigrating(false);
      expect(await stakingV2.migrating()).to.be.false;
    });
  });

  describe("toMigrateId", () => {
    it("toMigrateId should be not null if not migrated", async () => {
      expect(await stakingV2.toMigrateId(stakingMaxAddress)).to.be.gt(1);
    });

    it("toMigrateId should be null if migrated", async () => {
      await (await stakingV2.connect(stakingMaxAccount).migrate()).wait();
      expect(await stakingV2.toMigrateId(stakingMaxAddress)).to.be.equal(0);
    });

    it("toMigrateId should be null if not v1 address", async () => {
      expect(await stakingV2.toMigrateId(secondAddress)).to.be.equal(0);
    });
  });

  describe("setMigrator", () => {
    it("setMigrator should work", async () => {
      // admin is migrator at init => setMigrator to second account
      await stakingV2.connect(admin).setMigrator(secondAddress);

      // now second account is migrator => addUserToMigrate should not revert
      await expect(
        stakingV2.connect(secondAccount).addUserToMigrate(secondAddress, 1, 1)
      ).to.not.be.reverted;
    });

    it("setMigrator should work if migrator", async () => {
      // admin is migrator at init => setMigrator should not revert
      await expect(stakingV2.connect(admin).setMigrator(secondAddress)).to.not
        .be.reverted;
    });

    it("setMigrator should fail if not migrator", async () => {
      // second account not migrator => setMigrator should revert
      await expect(
        stakingV2.connect(secondAccount).setMigrator(secondAddress)
      ).to.be.revertedWith("not migrator");
    });
  });

  describe("staking share V2", () => {
    const getBondV2 = async (
      _user: Signer,
      _lp = 1,
      _weeks = 208
    ): Promise<Bond> => {
      const address = await _user.getAddress();

      await stakingV2.connect(admin).addUserToMigrate(address, _lp, _weeks);
      await (await stakingV2.connect(_user).migrate()).wait();

      const id = (await stakingShareV2.holderTokens(address))[0];
      const bond = await stakingShareV2.getBond(id);

      return bond;
    };

    it("staking share V2 should be minted with incremental ID", async () => {
      await (await stakingV2.connect(stakingMinAccount).migrate()).wait();
      await (await stakingV2.connect(stakingMaxAccount).migrate()).wait();

      const idsMin = await stakingShareV2.holderTokens(stakingMinAddress);
      const idsMax = await stakingShareV2.holderTokens(stakingMaxAddress);
      expect(idsMax[0].sub(idsMin[0])).to.be.equal(1);
      expect(idsMax[0]).to.be.equal(2);
    });

    it("staking share V2 with Zero LP should not increment ID", async () => {
      await expect(stakingV2.connect(stakingZeroAccount).migrate()).to.be
        .reverted;
      await (await stakingV2.connect(stakingMaxAccount).migrate()).wait();

      expect(
        (await stakingShareV2.holderTokens(stakingMaxAddress))[0]
      ).to.be.equal(1);
    });

    it("staking share V2 should have endblock according to weeks param", async () => {
      const blockCountInAWeek: BigNumber = BigNumber.from(20000);
      await stakingV2.setBlockCountInAWeek(blockCountInAWeek);

      const bond = await getBondV2(secondAccount, 42, 208);

      expect(bond.endBlock).to.be.equal(
        bond.creationBlock.add(blockCountInAWeek.mul(208))
      );
    });

    it("staking share V2 should have LP amount according to LP param", async () => {
      const bond = await getBondV2(secondAccount, 2, 208);

      expect(bond.lpAmount).to.be.equal(2);
    });

    it("staking share V2 should have appropriate minter", async () => {
      const bond = await getBondV2(secondAccount, 2, 208);

      expect(bond.minter).to.be.equal(secondAddress);
    });
    it("staking share V2 should have appropriate lpRewardDebt and shares", async () => {
      const totalLpToMigrateBeforeMinMigrate =
        await stakingV2.totalLpToMigrate();
      await stakingV2.connect(stakingMinAccount).migrate();
      const totalLpToMigrateAfterMinMigrate =
        await stakingV2.totalLpToMigrate();
      const idsMin = await stakingShareV2.holderTokens(stakingMinAddress);
      expect(idsMin.length).to.equal(1);

      let pendingLpRewardsMin = await stakingV2.pendingLpRewards(idsMin[0]);

      const stakingV2Bal = await metaPool.balanceOf(stakingV2.address);
      expect(stakingV2Bal).to.equal(stakingMaxBalance.add(stakingMinBalance));
      let totalLP = await stakingShareV2.totalLP();
      expect(totalLP).to.equal(stakingMinBalance);
      const bondMin = await stakingShareV2.getBond(idsMin[0]);
      const zz1 = await stakingV2.stakingDiscountMultiplier(); // zz1 = zerozero1 = 0.001 ether = 10^16
      const calculatedSharesForMin = BigNumber.from(
        await ubiquityFormulas.durationMultiply(bondMin.lpAmount, 1, zz1)
      );
      const shareMinDetail = await masterChefV2.getStakingShareInfo(idsMin[0]);

      expect(shareMinDetail[0]).to.equal(calculatedSharesForMin);

      expect(totalLpToMigrateBeforeMinMigrate).to.equal(
        totalLpToMigrateAfterMinMigrate.add(bondMin.lpAmount)
      );
      expect(bondMin.lpRewardDebt).to.be.equal(0);
      // simulate distribution of lp token to assess the update of lpRewardDebt
      const extraLPAmount = one.mul(10);
      await metaPool.transfer(stakingV2.address, extraLPAmount);
      const totalLpToMigrateBeforeMaxMigrate =
        await stakingV2.totalLpToMigrate();
      await stakingV2.connect(stakingMaxAccount).migrate();
      const totalLpToMigrateAfterMaxMigrate =
        await stakingV2.totalLpToMigrate();

      const idsMax = await stakingShareV2.holderTokens(stakingMaxAddress);
      const bondMax = await stakingShareV2.getBond(idsMax[0]);
      const calculatedSharesForMax = BigNumber.from(
        await ubiquityFormulas.durationMultiply(bondMax.lpAmount, 208, zz1)
      );
      const shareMaxDetail = await masterChefV2.getStakingShareInfo(idsMax[0]);
      expect(shareMaxDetail[0]).to.equal(calculatedSharesForMax);

      expect(totalLpToMigrateBeforeMaxMigrate).to.equal(
        totalLpToMigrateAfterMaxMigrate.add(bondMax.lpAmount)
      );
      expect(bondMax.lpRewardDebt).to.be.equal("39958228383176416936");
      const pendingLpRewardsMax = await stakingV2.pendingLpRewards(idsMax[0]);
      expect(pendingLpRewardsMax).to.equal(0);
      const stakingV2BalAfter = await metaPool.balanceOf(stakingV2.address);
      expect(stakingV2BalAfter).to.equal(
        bondMin.lpAmount.add(bondMax.lpAmount).add(extraLPAmount)
      );
      totalLP = await stakingShareV2.totalLP();
      expect(totalLP).to.equal(stakingMaxBalance.add(stakingMinBalance));
      // stakingMin account should be entitled to some rewards as the extraLPAmount
      // occurs after his migration
      pendingLpRewardsMin = await stakingV2.pendingLpRewards(idsMin[0]);

      const isPrecise = isAmountEquivalent(
        pendingLpRewardsMin.toString(),
        extraLPAmount.toString(),
        "0.0000000001"
      );
      expect(isPrecise).to.be.true;

      expect(idsMax.length).to.equal(1);
      // send the LP token from staking V1 to V2 to prepare the migration
      // simulate distribution of lp token to assess the update of lpRewardDebt
      const extraLPSecondAmount = one.mul(42);
      await metaPool.transfer(stakingV2.address, extraLPSecondAmount);
      const pendingLpRewardsMinSecond = await stakingV2.pendingLpRewards(
        idsMin[0]
      );
      expect(pendingLpRewardsMinSecond).to.be.gt(pendingLpRewardsMin);
      const pendingLpRewardsMaxSecond = await stakingV2.pendingLpRewards(
        idsMax[0]
      );
      expect(pendingLpRewardsMaxSecond).to.be.gt(pendingLpRewardsMax);
      const isRewardPrecise = isAmountEquivalent(
        pendingLpRewardsMaxSecond.add(pendingLpRewardsMinSecond).toString(),
        extraLPAmount.add(extraLPSecondAmount).toString(),
        "0.0000000001"
      );
      expect(isRewardPrecise).to.be.true;
    });
  });
});
