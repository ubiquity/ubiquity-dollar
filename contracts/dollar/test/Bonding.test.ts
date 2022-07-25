import { ethers, Signer } from "ethers";
import { describe, it } from "mocha";
import { expect } from "./setup";
import { UbiquityAlgorithmicDollar } from "../artifacts/types/UbiquityAlgorithmicDollar";
import { TWAPOracle } from "../artifacts/types/TWAPOracle";
import { Bonding } from "../artifacts/types/Bonding";
import { bondingSetup } from "./BondingSetup";

describe("Bonding", () => {
  let bonding: Bonding;
  let admin: Signer;
  let secondAccount: Signer;
  let uAD: UbiquityAlgorithmicDollar;
  let sablier: string;
  let DAI: string;
  let USDC: string;
  let twapOracle: TWAPOracle;

  before(async () => {
    ({ admin, secondAccount, uAD, bonding, twapOracle, sablier, DAI, USDC } = await bondingSetup());
  });
  describe("CollectableDust", () => {
    it("Admin should be able to add protocol token (CollectableDust)", async () => {
      await bonding.connect(admin).addProtocolToken(USDC);
    });

    it("should revert when another account tries to add protocol token (CollectableDust)", async () => {
      await expect(bonding.connect(secondAccount).addProtocolToken(USDC)).to.be.revertedWith("Caller is not a bonding manager");
    });

    it("should revert when trying to add an already existing protocol token (CollectableDust)", async () => {
      await expect(bonding.connect(admin).addProtocolToken(USDC)).to.be.revertedWith("collectable-dust::token-is-part-of-the-protocol");
    });

    it("should revert when another account tries to remove a protocol token (CollectableDust)", async () => {
      await expect(bonding.connect(secondAccount).removeProtocolToken(USDC)).to.be.revertedWith("Caller is not a bonding manager");
    });

    it("Admin should be able to remove protocol token (CollectableDust)", async () => {
      await bonding.connect(admin).removeProtocolToken(USDC);
    });

    it("should revert when trying to remove token that is not a part of the protocol (CollectableDust)", async () => {
      await expect(bonding.connect(admin).removeProtocolToken(USDC)).to.be.revertedWith("collectable-dust::token-not-part-of-the-protocol");
    });

    it("Admin should be able to send dust from the contract (CollectableDust)", async () => {
      // Send ETH to the Bonding contract
      await secondAccount.sendTransaction({
        to: bonding.address,
        value: ethers.utils.parseUnits("100", "gwei"),
      });

      // Send dust back to the admin
      await bonding.connect(admin).sendDust(await admin.getAddress(), await bonding.ETH_ADDRESS(), ethers.utils.parseUnits("50", "gwei"));
    });

    it("should emit DustSent event (CollectableDust)", async () => {
      await expect(bonding.connect(admin).sendDust(await admin.getAddress(), await bonding.ETH_ADDRESS(), ethers.utils.parseUnits("50", "gwei")))
        .to.emit(bonding, "DustSent")
        .withArgs(await admin.getAddress(), await bonding.ETH_ADDRESS(), ethers.utils.parseUnits("50", "gwei"));
    });
    it("should revert when another account tries to remove dust from the contract (CollectableDust)", async () => {
      await expect(
        bonding.connect(secondAccount).sendDust(await admin.getAddress(), await bonding.ETH_ADDRESS(), ethers.utils.parseUnits("100", "gwei"))
      ).to.be.revertedWith("Caller is not a bonding manager");
    });

    it("should emit ProtocolTokenAdded event (CollectableDust)", async () => {
      await expect(bonding.connect(admin).addProtocolToken(DAI)).to.emit(bonding, "ProtocolTokenAdded").withArgs(DAI);
    });

    it("should emit ProtocolTokenRemoved event (CollectableDust)", async () => {
      await expect(bonding.connect(admin).removeProtocolToken(DAI)).to.emit(bonding, "ProtocolTokenRemoved").withArgs(DAI);
    });
  });

  describe("blockCountInAWeek", () => {
    it("Admin should be able to update the blockCountInAWeek", async () => {
      await bonding.connect(admin).setBlockCountInAWeek(ethers.BigNumber.from(2));
      expect(await bonding.blockCountInAWeek()).to.equal(ethers.BigNumber.from(2));
    });

    it("should revert when unauthorized accounts try to update the bondingDiscountMultiplier", async () => {
      await expect(bonding.connect(secondAccount).setBlockCountInAWeek(ethers.BigNumber.from(2))).to.be.revertedWith("Caller is not a bonding manager");
    });

    it("should emit the BondingDiscountMultiplierUpdated event", async () => {
      await expect(bonding.connect(admin).setBlockCountInAWeek(ethers.BigNumber.from(2)))
        .to.emit(bonding, "BlockCountInAWeekUpdated")
        .withArgs(ethers.BigNumber.from(2));
    });
  });

  describe("bondingDiscountMultiplier", () => {
    it("Admin should be able to update the bondingDiscountMultiplier", async () => {
      await bonding.connect(admin).setBondingDiscountMultiplier(ethers.BigNumber.from(2));
      expect(await bonding.bondingDiscountMultiplier()).to.equal(ethers.BigNumber.from(2));
    });

    it("should revert when unauthorized accounts try to update the bondingDiscountMultiplier", async () => {
      await expect(bonding.connect(secondAccount).setBondingDiscountMultiplier(ethers.BigNumber.from(2))).to.be.revertedWith("Caller is not a bonding manager");
    });

    it("should emit the BondingDiscountMultiplierUpdated event", async () => {
      await expect(bonding.connect(admin).setBondingDiscountMultiplier(ethers.BigNumber.from(2)))
        .to.emit(bonding, "BondingDiscountMultiplierUpdated")
        .withArgs(ethers.BigNumber.from(2));
    });
  });

  describe("redeemStreamTime", () => {
    it("Admin should be able to update the redeemStreamTime", async () => {
      await bonding.connect(admin).setRedeemStreamTime(ethers.BigNumber.from("0"));

      expect(await bonding.redeemStreamTime()).to.equal(ethers.BigNumber.from("0"));
    });

    it("should revert when unauthorized accounts try to update the redeemStreamTime", async () => {
      await expect(bonding.connect(secondAccount).setRedeemStreamTime(ethers.BigNumber.from(0))).to.be.revertedWith("Caller is not a bonding manager");
    });

    it("should emit the RedeemStreamTimeUpdated event", async () => {
      await expect(bonding.connect(admin).setRedeemStreamTime(ethers.BigNumber.from("604800")))
        .to.emit(bonding, "RedeemStreamTimeUpdated")
        .withArgs(ethers.BigNumber.from("604800"));
    });
  });

  describe("StableSwap meta pool TWAP oracle", () => {
    it("Oracle should return the correct initial price", async () => {
      expect(await twapOracle.consult(uAD.address)).to.equal(ethers.utils.parseEther("1"));
    });
  });

  describe("Sablier configuration", () => {
    it("should return the current Sablier address", async () => {
      expect(await bonding.sablier()).to.equal(sablier);
    });

    it("admin should be able to update the Sablier address", async () => {
      await bonding.connect(admin).setSablier(ethers.constants.AddressZero);
      expect(await bonding.sablier()).to.equal(ethers.constants.AddressZero);
    });

    it("should emit the SablierUpdated event", async () => {
      await expect(bonding.connect(admin).setSablier(DAI)).to.emit(bonding, "SablierUpdated").withArgs(DAI);
    });

    it("should revert when another account tries to update the Sablier address", async () => {
      await expect(bonding.connect(secondAccount).setSablier(ethers.constants.AddressZero)).to.be.revertedWith("Caller is not a bonding manager");
    });
  });
});
