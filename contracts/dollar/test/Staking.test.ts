import { ethers, Signer } from "ethers";
import { describe, it } from "mocha";
import { expect } from "./setup";
import { UbiquityAlgorithmicDollar } from "../artifacts/types/UbiquityAlgorithmicDollar";
import { TWAPOracle } from "../artifacts/types/TWAPOracle";
import { Staking } from "../artifacts/types/Staking";
import { stakingSetup } from "./StakingSetup";

describe("Staking", () => {
  let staking: Staking;
  let admin: Signer;
  let secondAccount: Signer;
  let uAD: UbiquityAlgorithmicDollar;
  let sablier: string;
  let DAI: string;
  let USDC: string;
  let twapOracle: TWAPOracle;

  before(async () => {
    ({ admin, secondAccount, uAD, staking, twapOracle, sablier, DAI, USDC } =
      await stakingSetup());
  });
  describe("CollectableDust", () => {
    it("Admin should be able to add protocol token (CollectableDust)", async () => {
      await staking.connect(admin).addProtocolToken(USDC);
    });

    it("should revert when another account tries to add protocol token (CollectableDust)", async () => {
      await expect(
        staking.connect(secondAccount).addProtocolToken(USDC)
      ).to.be.revertedWith("Caller is not a staking manager");
    });

    it("should revert when trying to add an already existing protocol token (CollectableDust)", async () => {
      await expect(
        staking.connect(admin).addProtocolToken(USDC)
      ).to.be.revertedWith("collectable-dust::token-is-part-of-the-protocol");
    });

    it("should revert when another account tries to remove a protocol token (CollectableDust)", async () => {
      await expect(
        staking.connect(secondAccount).removeProtocolToken(USDC)
      ).to.be.revertedWith("Caller is not a staking manager");
    });

    it("Admin should be able to remove protocol token (CollectableDust)", async () => {
      await staking.connect(admin).removeProtocolToken(USDC);
    });

    it("should revert when trying to remove token that is not a part of the protocol (CollectableDust)", async () => {
      await expect(
        staking.connect(admin).removeProtocolToken(USDC)
      ).to.be.revertedWith("collectable-dust::token-not-part-of-the-protocol");
    });

    it("Admin should be able to send dust from the contract (CollectableDust)", async () => {
      // Send ETH to the Staking contract
      await secondAccount.sendTransaction({
        to: staking.address,
        value: ethers.utils.parseUnits("100", "gwei"),
      });

      // Send dust back to the admin
      await staking
        .connect(admin)
        .sendDust(
          await admin.getAddress(),
          await staking.ETH_ADDRESS(),
          ethers.utils.parseUnits("50", "gwei")
        );
    });

    it("should emit DustSent event (CollectableDust)", async () => {
      await expect(
        staking
          .connect(admin)
          .sendDust(
            await admin.getAddress(),
            await staking.ETH_ADDRESS(),
            ethers.utils.parseUnits("50", "gwei")
          )
      )
        .to.emit(staking, "DustSent")
        .withArgs(
          await admin.getAddress(),
          await staking.ETH_ADDRESS(),
          ethers.utils.parseUnits("50", "gwei")
        );
    });
    it("should revert when another account tries to remove dust from the contract (CollectableDust)", async () => {
      await expect(
        staking
          .connect(secondAccount)
          .sendDust(
            await admin.getAddress(),
            await staking.ETH_ADDRESS(),
            ethers.utils.parseUnits("100", "gwei")
          )
      ).to.be.revertedWith("Caller is not a staking manager");
    });

    it("should emit ProtocolTokenAdded event (CollectableDust)", async () => {
      await expect(staking.connect(admin).addProtocolToken(DAI))
        .to.emit(staking, "ProtocolTokenAdded")
        .withArgs(DAI);
    });

    it("should emit ProtocolTokenRemoved event (CollectableDust)", async () => {
      await expect(staking.connect(admin).removeProtocolToken(DAI))
        .to.emit(staking, "ProtocolTokenRemoved")
        .withArgs(DAI);
    });
  });

  describe("blockCountInAWeek", () => {
    it("Admin should be able to update the blockCountInAWeek", async () => {
      await staking
        .connect(admin)
        .setBlockCountInAWeek(ethers.BigNumber.from(2));
      expect(await staking.blockCountInAWeek()).to.equal(
        ethers.BigNumber.from(2)
      );
    });

    it("should revert when unauthorized accounts try to update the stakingDiscountMultiplier", async () => {
      await expect(
        staking
          .connect(secondAccount)
          .setBlockCountInAWeek(ethers.BigNumber.from(2))
      ).to.be.revertedWith("Caller is not a staking manager");
    });

    it("should emit the StakingDiscountMultiplierUpdated event", async () => {
      await expect(
        staking.connect(admin).setBlockCountInAWeek(ethers.BigNumber.from(2))
      )
        .to.emit(staking, "BlockCountInAWeekUpdated")
        .withArgs(ethers.BigNumber.from(2));
    });
  });

  describe("stakingDiscountMultiplier", () => {
    it("Admin should be able to update the stakingDiscountMultiplier", async () => {
      await staking
        .connect(admin)
        .setStakingDiscountMultiplier(ethers.BigNumber.from(2));
      expect(await staking.stakingDiscountMultiplier()).to.equal(
        ethers.BigNumber.from(2)
      );
    });

    it("should revert when unauthorized accounts try to update the stakingDiscountMultiplier", async () => {
      await expect(
        staking
          .connect(secondAccount)
          .setStakingDiscountMultiplier(ethers.BigNumber.from(2))
      ).to.be.revertedWith("Caller is not a staking manager");
    });

    it("should emit the StakingDiscountMultiplierUpdated event", async () => {
      await expect(
        staking
          .connect(admin)
          .setStakingDiscountMultiplier(ethers.BigNumber.from(2))
      )
        .to.emit(staking, "StakingDiscountMultiplierUpdated")
        .withArgs(ethers.BigNumber.from(2));
    });
  });

  describe("redeemStreamTime", () => {
    it("Admin should be able to update the redeemStreamTime", async () => {
      await staking
        .connect(admin)
        .setRedeemStreamTime(ethers.BigNumber.from("0"));

      expect(await staking.redeemStreamTime()).to.equal(
        ethers.BigNumber.from("0")
      );
    });

    it("should revert when unauthorized accounts try to update the redeemStreamTime", async () => {
      await expect(
        staking
          .connect(secondAccount)
          .setRedeemStreamTime(ethers.BigNumber.from(0))
      ).to.be.revertedWith("Caller is not a staking manager");
    });

    it("should emit the RedeemStreamTimeUpdated event", async () => {
      await expect(
        staking
          .connect(admin)
          .setRedeemStreamTime(ethers.BigNumber.from("604800"))
      )
        .to.emit(staking, "RedeemStreamTimeUpdated")
        .withArgs(ethers.BigNumber.from("604800"));
    });
  });

  describe("StableSwap meta pool TWAP oracle", () => {
    it("Oracle should return the correct initial price", async () => {
      expect(await twapOracle.consult(uAD.address)).to.equal(
        ethers.utils.parseEther("1")
      );
    });
  });

  describe("Sablier configuration", () => {
    it("should return the current Sablier address", async () => {
      expect(await staking.sablier()).to.equal(sablier);
    });

    it("admin should be able to update the Sablier address", async () => {
      await staking.connect(admin).setSablier(ethers.constants.AddressZero);
      expect(await staking.sablier()).to.equal(ethers.constants.AddressZero);
    });

    it("should emit the SablierUpdated event", async () => {
      await expect(staking.connect(admin).setSablier(DAI))
        .to.emit(staking, "SablierUpdated")
        .withArgs(DAI);
    });

    it("should revert when another account tries to update the Sablier address", async () => {
      await expect(
        staking.connect(secondAccount).setSablier(ethers.constants.AddressZero)
      ).to.be.revertedWith("Caller is not a staking manager");
    });
  });
});
