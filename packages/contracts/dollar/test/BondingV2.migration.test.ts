import { expect } from "chai";
import { Signer, BigNumber } from "ethers";
import { BondingV2 } from "../artifacts/types/BondingV2";
import { BondingShareV2 } from "../artifacts/types/BondingShareV2";
import { bondingSetupV2 } from "./BondingSetupV2";
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
let bondingV2: BondingV2;
let bondingShareV2: BondingShareV2;
let masterChefV2: MasterChefV2;
let secondAccount: Signer;
let ubiquityFormulas: UbiquityFormulas;
let metaPool: IMetaPool;
let bondingMinBalance: BigNumber;
let bondingMaxBalance: BigNumber;
let bondingZeroAccount: Signer;
let bondingMinAccount: Signer;
let bondingMaxAccount: Signer;
let bondingMinAddress: string;
let bondingMaxAddress: string;
let secondAddress: string;
let admin: Signer;

describe("bondingV2 migration", () => {
  beforeEach(async () => {
    ({
      admin,
      secondAccount,
      masterChefV2,
      ubiquityFormulas,
      metaPool,
      bondingV2,
      bondingShareV2,
      bondingZeroAccount,
      bondingMinAccount,
      bondingMinBalance,
      bondingMaxAccount,
      bondingMaxBalance,
    } = await bondingSetupV2());
    secondAddress = await secondAccount.getAddress();
    bondingMinAddress = await bondingMinAccount.getAddress();
    bondingMaxAddress = await bondingMaxAccount.getAddress();
  });
  describe("migrate", () => {
    it("migrate should work", async () => {
      await expect(bondingV2.connect(bondingMaxAccount).migrate()).to.not.be.reverted;
    });

    it("migrate should fail second time", async () => {
      await expect(bondingV2.connect(bondingMaxAccount).migrate()).to.not.be.reverted;

      await expect(bondingV2.connect(bondingMaxAccount).migrate()).to.be.revertedWith("not v1 address");
    });

    it("migrate should fail if msg.sender is not a user to migrate", async () => {
      // second account not v1 => migrate should revert
      await expect(bondingV2.connect(admin).migrate()).to.be.revertedWith("not v1 address");
    });

    it("migrate should fail if not in migration", async () => {
      await bondingV2.connect(admin).setMigrating(false);
      await expect(bondingV2.connect(bondingMinAccount).migrate()).to.be.revertedWith("not in migration");

      await bondingV2.connect(admin).setMigrating(true);
      await expect(bondingV2.connect(bondingMinAccount).migrate()).to.not.be.reverted;
    });

    it("migrate should fail if user LP amount to migrate is 0", async () => {
      await expect(bondingV2.connect(bondingZeroAccount).migrate()).to.be.revertedWith("LP amount is zero");
    });

    it("migrate should raise event", async () => {
      await expect(bondingV2.connect(bondingMinAccount).migrate()).to.emit(bondingV2, "Migrated");
    });
  });

  describe("addUserToMigrate", () => {
    it("addUserToMigrate should work if migrator", async () => {
      await expect(bondingV2.connect(admin).addUserToMigrate(secondAddress, 1, 1)).to.not.be.reverted;
    });

    it("addUserToMigrate should fail if not migrator", async () => {
      await expect(bondingV2.connect(bondingMaxAccount).addUserToMigrate(secondAddress, 1, 1)).to.be.revertedWith("not migrator");
    });

    it("addUserToMigrate should permit user to migrate", async () => {
      await expect(bondingV2.connect(admin).addUserToMigrate(secondAddress, 1, 1)).to.not.be.reverted;

      await expect(bondingV2.connect(secondAccount).migrate()).to.not.be.reverted;
    });

    it("addUserToMigrate should give id to user", async () => {
      await bondingV2.connect(admin).addUserToMigrate(secondAddress, 1, 1);

      expect(await bondingV2.toMigrateId(secondAddress)).to.be.gt(1);
    });
  });

  describe("migrating", () => {
    it("migrating should be true if in migration", async () => {
      expect(await bondingV2.migrating()).to.be.true;
    });

    it("migrating should be false if not in migration", async () => {
      await bondingV2.connect(admin).setMigrating(false);
      expect(await bondingV2.migrating()).to.be.false;
    });
  });

  describe("toMigrateId", () => {
    it("toMigrateId should be not null if not migrated", async () => {
      expect(await bondingV2.toMigrateId(bondingMaxAddress)).to.be.gt(1);
    });

    it("toMigrateId should be null if migrated", async () => {
      await (await bondingV2.connect(bondingMaxAccount).migrate()).wait();
      expect(await bondingV2.toMigrateId(bondingMaxAddress)).to.be.equal(0);
    });

    it("toMigrateId should be null if not v1 address", async () => {
      expect(await bondingV2.toMigrateId(secondAddress)).to.be.equal(0);
    });
  });

  describe("setMigrator", () => {
    it("setMigrator should work", async () => {
      // admin is migrator at init => setMigrator to second account
      await bondingV2.connect(admin).setMigrator(secondAddress);

      // now second account is migrator => addUserToMigrate should not revert
      await expect(bondingV2.connect(secondAccount).addUserToMigrate(secondAddress, 1, 1)).to.not.be.reverted;
    });

    it("setMigrator should work if migrator", async () => {
      // admin is migrator at init => setMigrator should not revert
      await expect(bondingV2.connect(admin).setMigrator(secondAddress)).to.not.be.reverted;
    });

    it("setMigrator should fail if not migrator", async () => {
      // second account not migrator => setMigrator should revert
      await expect(bondingV2.connect(secondAccount).setMigrator(secondAddress)).to.be.revertedWith("not migrator");
    });
  });

  describe("bonding share V2", () => {
    const getBondV2 = async (_user: Signer, _lp = 1, _weeks = 208): Promise<Bond> => {
      const address = await _user.getAddress();

      await bondingV2.connect(admin).addUserToMigrate(address, _lp, _weeks);
      await (await bondingV2.connect(_user).migrate()).wait();

      const id = (await bondingShareV2.holderTokens(address))[0];
      const bond = await bondingShareV2.getBond(id);

      return bond;
    };

    it("bonding share V2 should be minted with incremental ID", async () => {
      await (await bondingV2.connect(bondingMinAccount).migrate()).wait();
      await (await bondingV2.connect(bondingMaxAccount).migrate()).wait();

      const idsMin = await bondingShareV2.holderTokens(bondingMinAddress);
      const idsMax = await bondingShareV2.holderTokens(bondingMaxAddress);
      expect(idsMax[0].sub(idsMin[0])).to.be.equal(1);
      expect(idsMax[0]).to.be.equal(2);
    });

    it("bonding share V2 with Zero LP should not increment ID", async () => {
      await expect(bondingV2.connect(bondingZeroAccount).migrate()).to.be.reverted;
      await (await bondingV2.connect(bondingMaxAccount).migrate()).wait();

      expect((await bondingShareV2.holderTokens(bondingMaxAddress))[0]).to.be.equal(1);
    });

    it("bonding share V2 should have endblock according to weeks param", async () => {
      const blockCountInAWeek: BigNumber = BigNumber.from(20000);
      await bondingV2.setBlockCountInAWeek(blockCountInAWeek);

      const bond = await getBondV2(secondAccount, 42, 208);

      expect(bond.endBlock).to.be.equal(bond.creationBlock.add(blockCountInAWeek.mul(208)));
    });

    it("bonding share V2 should have LP amount according to LP param", async () => {
      const bond = await getBondV2(secondAccount, 2, 208);

      expect(bond.lpAmount).to.be.equal(2);
    });

    it("bonding share V2 should have appropriate minter", async () => {
      const bond = await getBondV2(secondAccount, 2, 208);

      expect(bond.minter).to.be.equal(secondAddress);
    });
    it("bonding share V2 should have appropriate lpRewardDebt and shares", async () => {
      const totalLpToMigrateBeforeMinMigrate = await bondingV2.totalLpToMigrate();
      await bondingV2.connect(bondingMinAccount).migrate();
      const totalLpToMigrateAfterMinMigrate = await bondingV2.totalLpToMigrate();
      const idsMin = await bondingShareV2.holderTokens(bondingMinAddress);
      expect(idsMin.length).to.equal(1);

      let pendingLpRewardsMin = await bondingV2.pendingLpRewards(idsMin[0]);

      const bondingV2Bal = await metaPool.balanceOf(bondingV2.address);
      expect(bondingV2Bal).to.equal(bondingMaxBalance.add(bondingMinBalance));
      let totalLP = await bondingShareV2.totalLP();
      expect(totalLP).to.equal(bondingMinBalance);
      const bondMin = await bondingShareV2.getBond(idsMin[0]);
      const zz1 = await bondingV2.bondingDiscountMultiplier(); // zz1 = zerozero1 = 0.001 ether = 10^16
      const calculatedSharesForMin = BigNumber.from(await ubiquityFormulas.durationMultiply(bondMin.lpAmount, 1, zz1));
      const shareMinDetail = await masterChefV2.getBondingShareInfo(idsMin[0]);

      expect(shareMinDetail[0]).to.equal(calculatedSharesForMin);

      expect(totalLpToMigrateBeforeMinMigrate).to.equal(totalLpToMigrateAfterMinMigrate.add(bondMin.lpAmount));
      expect(bondMin.lpRewardDebt).to.be.equal(0);
      // simulate distribution of lp token to assess the update of lpRewardDebt
      const extraLPAmount = one.mul(10);
      await metaPool.transfer(bondingV2.address, extraLPAmount);
      const totalLpToMigrateBeforeMaxMigrate = await bondingV2.totalLpToMigrate();
      await bondingV2.connect(bondingMaxAccount).migrate();
      const totalLpToMigrateAfterMaxMigrate = await bondingV2.totalLpToMigrate();

      const idsMax = await bondingShareV2.holderTokens(bondingMaxAddress);
      const bondMax = await bondingShareV2.getBond(idsMax[0]);
      const calculatedSharesForMax = BigNumber.from(await ubiquityFormulas.durationMultiply(bondMax.lpAmount, 208, zz1));
      const shareMaxDetail = await masterChefV2.getBondingShareInfo(idsMax[0]);
      expect(shareMaxDetail[0]).to.equal(calculatedSharesForMax);

      expect(totalLpToMigrateBeforeMaxMigrate).to.equal(totalLpToMigrateAfterMaxMigrate.add(bondMax.lpAmount));
      expect(bondMax.lpRewardDebt).to.be.equal("39958228383176416936");
      const pendingLpRewardsMax = await bondingV2.pendingLpRewards(idsMax[0]);
      expect(pendingLpRewardsMax).to.equal(0);
      const bondingV2BalAfter = await metaPool.balanceOf(bondingV2.address);
      expect(bondingV2BalAfter).to.equal(bondMin.lpAmount.add(bondMax.lpAmount).add(extraLPAmount));
      totalLP = await bondingShareV2.totalLP();
      expect(totalLP).to.equal(bondingMaxBalance.add(bondingMinBalance));
      // bondingMin account should be entitled to some rewards as the extraLPAmount
      // occurs after his migration
      pendingLpRewardsMin = await bondingV2.pendingLpRewards(idsMin[0]);

      const isPrecise = isAmountEquivalent(pendingLpRewardsMin.toString(), extraLPAmount.toString(), "0.0000000001");
      expect(isPrecise).to.be.true;

      expect(idsMax.length).to.equal(1);
      // send the LP token from bonding V1 to V2 to prepare the migration
      // simulate distribution of lp token to assess the update of lpRewardDebt
      const extraLPSecondAmount = one.mul(42);
      await metaPool.transfer(bondingV2.address, extraLPSecondAmount);
      const pendingLpRewardsMinSecond = await bondingV2.pendingLpRewards(idsMin[0]);
      expect(pendingLpRewardsMinSecond).to.be.gt(pendingLpRewardsMin);
      const pendingLpRewardsMaxSecond = await bondingV2.pendingLpRewards(idsMax[0]);
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
