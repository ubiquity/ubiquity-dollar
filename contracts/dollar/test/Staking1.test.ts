import { expect } from "chai";
import { ethers, Signer, BigNumber } from "ethers";
import { Staking } from "../artifacts/types/Staking";
import { StakingShare } from "../artifacts/types/StakingShare";
import { UbiquityAlgorithmicDollar } from "../artifacts/types/UbiquityAlgorithmicDollar";
import { stakingSetup, deposit, withdraw } from "./StakingSetup";
import { mineNBlock } from "./utils/hardhatNode";

describe("Staking1", () => {
  let idBlock: number;
  const one: BigNumber = BigNumber.from(10).pow(18); // one = 1 ether = 10^18

  let uAD: UbiquityAlgorithmicDollar;
  let staking: Staking;
  let stakingShare: StakingShare;
  let sablier: string;
  let secondAccount: Signer;
  let blockCountInAWeek: BigNumber;
  before(async () => {
    ({ secondAccount, uAD, staking, stakingShare, sablier, blockCountInAWeek } =
      await stakingSetup());
  });
  describe("initialValues", () => {
    it("initial uAD totalSupply should be more than 30 010 (3 * 10 000 + 10)", async () => {
      const uADtotalSupply: BigNumber = await uAD.totalSupply();
      const uADinitialSupply: BigNumber = BigNumber.from(10).pow(18).mul(30010);

      expect(uADtotalSupply).to.gte(uADinitialSupply);
    });

    it("initial staking totalSupply should be 0", async () => {
      const bondTotalSupply: BigNumber = await stakingShare.totalSupply();
      const zero: BigNumber = BigNumber.from(0);

      expect(bondTotalSupply).to.eq(zero);
    });

    it("initial currentShareValue should be one", async () => {
      const currentShareValue: BigNumber = await staking.currentShareValue();
      const targetPrice: BigNumber = one;

      expect(currentShareValue).to.eq(targetPrice);
    });

    it("initial currentTokenPrice should be one", async () => {
      const currentTokenPrice: BigNumber = await staking.currentTokenPrice();
      const targetPrice: BigNumber = one;

      expect(currentTokenPrice).to.eq(targetPrice);
    });
  });

  describe("deposit", () => {
    it("User should be able to bond tokens", async () => {
      const { id, bond } = await deposit(secondAccount, one.mul(100), 1);
      idBlock = id;
      expect(bond).to.be.gte(one.mul(100));
      await mineNBlock(blockCountInAWeek.toNumber());
    });
  });

  describe("withdraw", () => {
    it("should revert when users try to redeem more shares than they have", async () => {
      await expect(
        staking
          .connect(secondAccount)
          .withdraw(ethers.utils.parseEther("10000"), idBlock)
      ).to.be.revertedWith("Staking: caller does not have enough shares");
    });
    it("Users should be able to redeem all their shares", async () => {
      const bondBefore: BigNumber = await stakingShare.balanceOf(
        await secondAccount.getAddress(),
        idBlock
      );
      const lp = await withdraw(secondAccount, idBlock);
      const bondAfter: BigNumber = await stakingShare.balanceOf(
        await secondAccount.getAddress(),
        idBlock
      );
      expect(lp).to.be.gt(0);
      expect(bondBefore).to.be.gt(0);
      expect(bondAfter).to.be.equal(0);
    });

    it("should return the current Sablier address", async () => {
      expect(await staking.sablier()).to.equal(sablier);
    });
  });
});
