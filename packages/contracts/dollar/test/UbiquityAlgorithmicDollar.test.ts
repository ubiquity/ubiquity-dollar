import { Signer } from "ethers";
import { ethers } from "hardhat";
import { expect } from "chai";
import { UbiquityAlgorithmicDollar } from "../artifacts/types/UbiquityAlgorithmicDollar";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";

describe("UbiquityAlgorithmicDollar", () => {
  let admin: Signer;
  let secondAccount: Signer;
  let thirdAccount: Signer;
  let manager: UbiquityAlgorithmicDollarManager;
  let uAD: UbiquityAlgorithmicDollar;
  const UBQ_BURNER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("UBQ_BURNER_ROLE"));

  beforeEach(async () => {
    [admin, secondAccount, thirdAccount] = await ethers.getSigners();
    const Manager = await ethers.getContractFactory("UbiquityAlgorithmicDollarManager");
    manager = (await Manager.deploy(await admin.getAddress())) as UbiquityAlgorithmicDollarManager;

    const UAD = await ethers.getContractFactory("UbiquityAlgorithmicDollar");
    uAD = (await UAD.deploy(manager.address)) as UbiquityAlgorithmicDollar;
  });
  describe("SetName", () => {
    const newName = "Super Moon UBQ";
    it("should work", async () => {
      const prevName = await uAD.name();
      expect(prevName).to.equal("Ubiquity Algorithmic Dollar");
      await uAD.connect(admin).setName(newName);
      const name = await uAD.name();
      expect(name).to.equal(newName);
    });
    it("should fail if not admin", async () => {
      await expect(uAD.connect(secondAccount).setName(newName)).to.revertedWith("ERC20: deployer must be manager admin");
    });
  });
  describe("SetSymbol", () => {
    const newSymbol = "UBMOON";
    it("should work", async () => {
      const prevSym = await uAD.symbol();
      expect(prevSym).to.equal("uAD");
      await uAD.connect(admin).setSymbol(newSymbol);
      const symbol = await uAD.symbol();
      expect(symbol).to.equal(newSymbol);
    });
    it("should fail if not admin", async () => {
      await expect(uAD.connect(secondAccount).setSymbol(newSymbol)).to.revertedWith("ERC20: deployer must be manager admin");
    });
  });
  describe("Transfer", () => {
    it("should work", async () => {
      const sndAdr = await secondAccount.getAddress();
      const thirdAdr = await thirdAccount.getAddress();
      await uAD.connect(admin).mint(sndAdr, ethers.utils.parseEther("10000"));
      expect(await uAD.balanceOf(sndAdr)).to.equal(ethers.utils.parseEther("10000"));
      // transfer uad
      await uAD.connect(secondAccount).transfer(thirdAdr, ethers.utils.parseEther("42"));
      expect(await uAD.balanceOf(sndAdr)).to.equal(ethers.utils.parseEther("9958"));
      expect(await uAD.balanceOf(thirdAdr)).to.equal(ethers.utils.parseEther("42"));
    });
    it("should fail if balance is insufficient", async () => {
      const sndAdr = await secondAccount.getAddress();
      const thirdAdr = await thirdAccount.getAddress();
      await uAD.connect(admin).mint(sndAdr, ethers.utils.parseEther("10000"));
      expect(await uAD.balanceOf(sndAdr)).to.equal(ethers.utils.parseEther("10000"));
      // transfer uad
      await expect(uAD.connect(secondAccount).transfer(thirdAdr, ethers.utils.parseEther("10000.0000000001"))).to.revertedWith(
        "ERC20: transfer amount exceeds balance"
      );
    });
  });
  describe("Mint", () => {
    it("should work", async () => {
      const sndAdr = await secondAccount.getAddress();
      await uAD.connect(admin).mint(sndAdr, ethers.utils.parseEther("10000"));
      expect(await uAD.balanceOf(sndAdr)).to.equal(ethers.utils.parseEther("10000"));
    });
    it("should fail if not Minter Role", async () => {
      const thirdAdr = await thirdAccount.getAddress();
      // transfer uad
      await expect(uAD.connect(secondAccount).mint(thirdAdr, ethers.utils.parseEther("10000"))).to.revertedWith("Governance token: not minter");
    });
  });
  describe("Burn", () => {
    it("should work", async () => {
      const sndAdr = await secondAccount.getAddress();
      await uAD.connect(admin).mint(sndAdr, ethers.utils.parseEther("10000"));
      expect(await uAD.balanceOf(sndAdr)).to.equal(ethers.utils.parseEther("10000"));
      await uAD.connect(secondAccount).burn(ethers.utils.parseEther("10000"));
      expect(await uAD.balanceOf(sndAdr)).to.equal(ethers.utils.parseEther("0"));
    });
    it("should fail if balance is insufficient", async () => {
      await expect(uAD.connect(secondAccount).burn(ethers.utils.parseEther("10000"))).to.revertedWith("ERC20: burn amount exceeds balance");
    });
  });
  describe("BurnFrom", () => {
    it("should fail", async () => {
      const sndAdr = await secondAccount.getAddress();
      await uAD.connect(admin).mint(sndAdr, ethers.utils.parseEther("10000"));
      expect(await uAD.balanceOf(sndAdr)).to.equal(ethers.utils.parseEther("10000"));
      await expect(uAD.connect(admin).burnFrom(sndAdr, ethers.utils.parseEther("10000"))).to.revertedWith("Governance token: not burner");
    });
    it("should work", async () => {
      const sndAdr = await secondAccount.getAddress();
      const admAdr = await admin.getAddress();

      await uAD.connect(admin).mint(sndAdr, ethers.utils.parseEther("10000"));
      expect(await uAD.balanceOf(sndAdr)).to.equal(ethers.utils.parseEther("10000"));
      await manager.grantRole(UBQ_BURNER_ROLE, admAdr);
      await uAD.connect(admin).burnFrom(sndAdr, ethers.utils.parseEther("10000"));
      expect(await uAD.balanceOf(sndAdr)).to.equal(ethers.utils.parseEther("0"));
    });
  });
});
