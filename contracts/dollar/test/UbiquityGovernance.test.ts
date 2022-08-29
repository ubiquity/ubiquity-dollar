import { Signer } from "ethers";
import { ethers } from "hardhat";
import { expect } from "chai";
import { UbiquityGovernance } from "../artifacts/types/UbiquityGovernance";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";

describe("UbiquityGovernance", () => {
  let admin: Signer;
  let secondAccount: Signer;
  let thirdAccount: Signer;
  let manager: UbiquityAlgorithmicDollarManager;
  let uGOV: UbiquityGovernance;
  const UBQ_BURNER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("UBQ_BURNER_ROLE"));

  beforeEach(async () => {
    [admin, secondAccount, thirdAccount] = await ethers.getSigners();
    const UADMgr = await ethers.getContractFactory("UbiquityAlgorithmicDollarManager");
    manager = (await UADMgr.deploy(await admin.getAddress())) as UbiquityAlgorithmicDollarManager;

    const UGOV = await ethers.getContractFactory("UbiquityGovernance");
    uGOV = (await UGOV.deploy(manager.address)) as UbiquityGovernance;
  });
  describe("SetName", () => {
    const newName = "Super Moon uGOV";
    it("should work", async () => {
      const prevName = await uGOV.name();
      expect(prevName).to.equal("Ubiquity");
      await uGOV.connect(admin).setName(newName);
      const name = await uGOV.name();
      expect(name).to.equal(newName);
    });
    it("should fail if not admin", async () => {
      await expect(uGOV.connect(secondAccount).setName(newName)).to.revertedWith("ERC20: deployer must be manager admin");
    });
  });
  describe("SetSymbol", () => {
    const newSymbol = "UGOVMOON";
    it("should work", async () => {
      const prevSym = await uGOV.symbol();
      expect(prevSym).to.equal("UBQ");
      await uGOV.connect(admin).setSymbol(newSymbol);
      const symbol = await uGOV.symbol();
      expect(symbol).to.equal(newSymbol);
    });
    it("should fail if not admin", async () => {
      await expect(uGOV.connect(secondAccount).setSymbol(newSymbol)).to.revertedWith("ERC20: deployer must be manager admin");
    });
  });
  describe("Transfer", () => {
    it("should work", async () => {
      const sndAdr = await secondAccount.getAddress();
      const thirdAdr = await thirdAccount.getAddress();
      await uGOV.connect(admin).mint(sndAdr, ethers.utils.parseEther("10000"));
      expect(await uGOV.balanceOf(sndAdr)).to.equal(ethers.utils.parseEther("10000"));
      // transfer uGOV
      await uGOV.connect(secondAccount).transfer(thirdAdr, ethers.utils.parseEther("42"));
      expect(await uGOV.balanceOf(sndAdr)).to.equal(ethers.utils.parseEther("9958"));
      expect(await uGOV.balanceOf(thirdAdr)).to.equal(ethers.utils.parseEther("42"));
    });
    it("should fail if balance is insufficient", async () => {
      const sndAdr = await secondAccount.getAddress();
      const thirdAdr = await thirdAccount.getAddress();
      await uGOV.connect(admin).mint(sndAdr, ethers.utils.parseEther("10000"));
      expect(await uGOV.balanceOf(sndAdr)).to.equal(ethers.utils.parseEther("10000"));
      // transfer uGOV
      await expect(uGOV.connect(secondAccount).transfer(thirdAdr, ethers.utils.parseEther("10000.0000000001"))).to.revertedWith(
        "ERC20: transfer amount exceeds balance"
      );
    });
  });
  describe("Mint", () => {
    it("should work", async () => {
      const sndAdr = await secondAccount.getAddress();
      await uGOV.connect(admin).mint(sndAdr, ethers.utils.parseEther("10000"));
      expect(await uGOV.balanceOf(sndAdr)).to.equal(ethers.utils.parseEther("10000"));
    });
    it("should fail if not Minter Role", async () => {
      const thirdAdr = await thirdAccount.getAddress();
      // transfer uGOV
      await expect(uGOV.connect(secondAccount).mint(thirdAdr, ethers.utils.parseEther("10000"))).to.revertedWith("Governance token: not minter");
    });
  });
  describe("Burn", () => {
    it("should work", async () => {
      const sndAdr = await secondAccount.getAddress();
      await uGOV.connect(admin).mint(sndAdr, ethers.utils.parseEther("10000"));
      expect(await uGOV.balanceOf(sndAdr)).to.equal(ethers.utils.parseEther("10000"));
      await uGOV.connect(secondAccount).burn(ethers.utils.parseEther("10000"));
      expect(await uGOV.balanceOf(sndAdr)).to.equal(ethers.utils.parseEther("0"));
    });
    it("should fail if balance is insufficient", async () => {
      await expect(uGOV.connect(secondAccount).burn(ethers.utils.parseEther("10000"))).to.revertedWith("ERC20: burn amount exceeds balance");
    });
  });
  describe("BurnFrom", () => {
    it("should fail", async () => {
      const sndAdr = await secondAccount.getAddress();
      await uGOV.connect(admin).mint(sndAdr, ethers.utils.parseEther("10000"));
      expect(await uGOV.balanceOf(sndAdr)).to.equal(ethers.utils.parseEther("10000"));
      await expect(uGOV.connect(admin).burnFrom(sndAdr, ethers.utils.parseEther("10000"))).to.revertedWith("Governance token: not burner");
    });
    it("should work", async () => {
      const sndAdr = await secondAccount.getAddress();
      const admAdr = await admin.getAddress();

      await uGOV.connect(admin).mint(sndAdr, ethers.utils.parseEther("10000"));
      expect(await uGOV.balanceOf(sndAdr)).to.equal(ethers.utils.parseEther("10000"));
      await manager.grantRole(UBQ_BURNER_ROLE, admAdr);
      await uGOV.connect(admin).burnFrom(sndAdr, ethers.utils.parseEther("10000"));
      expect(await uGOV.balanceOf(sndAdr)).to.equal(ethers.utils.parseEther("0"));
    });
  });
});
