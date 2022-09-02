import { ethers, Signer } from "ethers";
import { describe, it } from "mocha";
import { expect } from "./setup";
import { BondingV2 } from "../artifacts/types/BondingV2";
import { bondingSetupV2 } from "./BondingSetupV2";

describe("bondingV2 Setters", () => {
  let bondingV2: BondingV2;
  let admin: Signer;
  let secondAccount: Signer;
  let DAI: string;
  let USDC: string;

  before(async () => {
    ({ admin, secondAccount, bondingV2, DAI, USDC } = await bondingSetupV2());
  });
  describe("CollectableDust", () => {
    it("Admin should be able to add protocol token (CollectableDust)", async () => {
      await bondingV2.connect(admin).addProtocolToken(USDC);
    });

    it("should revert when another account tries to add protocol token (CollectableDust)", async () => {
      await expect(bondingV2.connect(secondAccount).addProtocolToken(USDC)).to.be.revertedWith("not manager");
    });

    it("should revert when trying to add an already existing protocol token (CollectableDust)", async () => {
      await expect(bondingV2.connect(admin).addProtocolToken(USDC)).to.be.revertedWith("collectable-dust::token-is-part-of-the-protocol");
    });

    it("should revert when another account tries to remove a protocol token (CollectableDust)", async () => {
      await expect(bondingV2.connect(secondAccount).removeProtocolToken(USDC)).to.be.revertedWith("not manager");
    });

    it("Admin should be able to remove protocol token (CollectableDust)", async () => {
      await bondingV2.connect(admin).removeProtocolToken(USDC);
    });

    it("should revert when trying to remove token that is not a part of the protocol (CollectableDust)", async () => {
      await expect(bondingV2.connect(admin).removeProtocolToken(USDC)).to.be.revertedWith("collectable-dust::token-not-part-of-the-protocol");
    });

    it("Admin should be able to send dust from the contract (CollectableDust)", async () => {
      // Send ETH to the Bonding contract
      await secondAccount.sendTransaction({
        to: bondingV2.address,
        value: ethers.utils.parseUnits("100", "gwei"),
      });

      // Send dust back to the admin
      await bondingV2.connect(admin).sendDust(await admin.getAddress(), await bondingV2.ETH_ADDRESS(), ethers.utils.parseUnits("50", "gwei"));
    });

    it("should emit DustSent event (CollectableDust)", async () => {
      await expect(bondingV2.connect(admin).sendDust(await admin.getAddress(), await bondingV2.ETH_ADDRESS(), ethers.utils.parseUnits("50", "gwei")))
        .to.emit(bondingV2, "DustSent")
        .withArgs(await admin.getAddress(), await bondingV2.ETH_ADDRESS(), ethers.utils.parseUnits("50", "gwei"));
    });
    it("should revert when another account tries to remove dust from the contract (CollectableDust)", async () => {
      await expect(
        bondingV2.connect(secondAccount).sendDust(await admin.getAddress(), await bondingV2.ETH_ADDRESS(), ethers.utils.parseUnits("100", "gwei"))
      ).to.be.revertedWith("not manager");
    });

    it("should emit ProtocolTokenAdded event (CollectableDust)", async () => {
      await expect(bondingV2.connect(admin).addProtocolToken(DAI)).to.emit(bondingV2, "ProtocolTokenAdded").withArgs(DAI);
    });

    it("should emit ProtocolTokenRemoved event (CollectableDust)", async () => {
      await expect(bondingV2.connect(admin).removeProtocolToken(DAI)).to.emit(bondingV2, "ProtocolTokenRemoved").withArgs(DAI);
    });
  });

  describe("blockCountInAWeek", () => {
    it("Admin should be able to update the blockCountInAWeek", async () => {
      await bondingV2.connect(admin).setBlockCountInAWeek(ethers.BigNumber.from(2));
      expect(await bondingV2.blockCountInAWeek()).to.equal(ethers.BigNumber.from(2));
    });

    it("should revert when unauthorized accounts try to update the bondingDiscountMultiplier", async () => {
      await expect(bondingV2.connect(secondAccount).setBlockCountInAWeek(ethers.BigNumber.from(2))).to.be.revertedWith("not manager");
    });

    it("should emit the BondingDiscountMultiplierUpdated event", async () => {
      await expect(bondingV2.connect(admin).setBlockCountInAWeek(ethers.BigNumber.from(2)))
        .to.emit(bondingV2, "BlockCountInAWeekUpdated")
        .withArgs(ethers.BigNumber.from(2));
    });
  });

  describe("bondingDiscountMultiplier", () => {
    it("Admin should be able to update the bondingDiscountMultiplier", async () => {
      await bondingV2.connect(admin).setBondingDiscountMultiplier(ethers.BigNumber.from(2));
      expect(await bondingV2.bondingDiscountMultiplier()).to.equal(ethers.BigNumber.from(2));
    });

    it("should revert when unauthorized accounts try to update the bondingDiscountMultiplier", async () => {
      await expect(bondingV2.connect(secondAccount).setBondingDiscountMultiplier(ethers.BigNumber.from(2))).to.be.revertedWith("not manager");
    });

    it("should emit the BondingDiscountMultiplierUpdated event", async () => {
      await expect(bondingV2.connect(admin).setBondingDiscountMultiplier(ethers.BigNumber.from(2)))
        .to.emit(bondingV2, "BondingDiscountMultiplierUpdated")
        .withArgs(ethers.BigNumber.from(2));
    });
  });
});
