import { expect } from "chai";
import { ethers, Signer, BigNumber } from "ethers";
import { Bonding } from "../artifacts/types/Bonding";
import { BondingShare } from "../artifacts/types/BondingShare";
import { UbiquityAlgorithmicDollar } from "../artifacts/types/UbiquityAlgorithmicDollar";
import { bondingSetup, deposit, withdraw } from "./BondingSetup";
import { mineNBlock } from "./utils/hardhatNode";

describe("Bonding1", () => {
  let idBlock: number;
  const one: BigNumber = BigNumber.from(10).pow(18); // one = 1 ether = 10^18

  let uAD: UbiquityAlgorithmicDollar;
  let bonding: Bonding;
  let bondingShare: BondingShare;
  let sablier: string;
  let secondAccount: Signer;
  let blockCountInAWeek: BigNumber;
  before(async () => {
    ({ secondAccount, uAD, bonding, bondingShare, sablier, blockCountInAWeek } = await bondingSetup());
  });
  describe("initialValues", () => {
    it("initial uAD totalSupply should be more than 30 010 (3 * 10 000 + 10)", async () => {
      const uADtotalSupply: BigNumber = await uAD.totalSupply();
      const uADinitialSupply: BigNumber = BigNumber.from(10).pow(18).mul(30010);

      expect(uADtotalSupply).to.gte(uADinitialSupply);
    });

    it("initial bonding totalSupply should be 0", async () => {
      const bondTotalSupply: BigNumber = await bondingShare.totalSupply();
      const zero: BigNumber = BigNumber.from(0);

      expect(bondTotalSupply).to.eq(zero);
    });

    it("initial currentShareValue should be one", async () => {
      const currentShareValue: BigNumber = await bonding.currentShareValue();
      const targetPrice: BigNumber = one;

      expect(currentShareValue).to.eq(targetPrice);
    });

    it("initial currentTokenPrice should be one", async () => {
      const currentTokenPrice: BigNumber = await bonding.currentTokenPrice();
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
      await expect(bonding.connect(secondAccount).withdraw(ethers.utils.parseEther("10000"), idBlock)).to.be.revertedWith(
        "Bonding: caller does not have enough shares"
      );
    });
    it("Users should be able to redeem all their shares", async () => {
      const bondBefore: BigNumber = await bondingShare.balanceOf(await secondAccount.getAddress(), idBlock);
      const lp = await withdraw(secondAccount, idBlock);
      const bondAfter: BigNumber = await bondingShare.balanceOf(await secondAccount.getAddress(), idBlock);
      expect(lp).to.be.gt(0);
      expect(bondBefore).to.be.gt(0);
      expect(bondAfter).to.be.equal(0);
    });

    it("should return the current Sablier address", async () => {
      expect(await bonding.sablier()).to.equal(sablier);
    });
  });
});
