import { BigNumber, Signer } from "ethers";
import { ethers, getNamedAccounts, network } from "hardhat";
import { expect } from "chai";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";
import { BondingShare } from "../artifacts/types/BondingShare";
import { ERC20 } from "../artifacts/types/ERC20";
import { UbiquityAutoRedeem } from "../artifacts/types/UbiquityAutoRedeem";
import { UARForDollarsCalculator } from "../artifacts/types/UARForDollarsCalculator";
import { UbiquityAlgorithmicDollar } from "../artifacts/types/UbiquityAlgorithmicDollar";
import { UbiquityGovernance } from "../artifacts/types/UbiquityGovernance";
import { DebtCoupon } from "../artifacts/types/DebtCoupon";
import { SushiSwapPool } from "../artifacts/types/SushiSwapPool";

describe("UbiquityAlgorithmicDollarManager", () => {
  // let bonding: Bonding;
  let debtCoupon: DebtCoupon;
  let manager: UbiquityAlgorithmicDollarManager;
  let admin: Signer;
  let uAD: UbiquityAlgorithmicDollar;
  let uAR: UbiquityAutoRedeem;
  let uarForDollarsCalculator: UARForDollarsCalculator;
  let uGOV: UbiquityGovernance;
  let curveFactory: string;
  let curve3CrvBasePool: string;
  let curve3CrvToken: string;
  let curveWhaleAddress: string;
  // let twapOracle: TWAPOracle;
  let bondingShare: BondingShare;

  beforeEach(async () => {
    ({ curveFactory, curve3CrvBasePool, curve3CrvToken, curveWhaleAddress } = await getNamedAccounts());
    [admin] = await ethers.getSigners();
    const UADMgr = await ethers.getContractFactory("UbiquityAlgorithmicDollarManager");
    manager = (await UADMgr.deploy(await admin.getAddress())) as UbiquityAlgorithmicDollarManager;

    const UAD = await ethers.getContractFactory("UbiquityAlgorithmicDollar");
    uAD = (await UAD.deploy(manager.address)) as UbiquityAlgorithmicDollar;

    const UAR = await ethers.getContractFactory("UbiquityAutoRedeem");
    uAR = (await UAR.deploy(manager.address)) as UbiquityAutoRedeem;

    const uarForDollarsCalculatorFactory = await ethers.getContractFactory("UARForDollarsCalculator");
    uarForDollarsCalculator = (await uarForDollarsCalculatorFactory.deploy(manager.address)) as UARForDollarsCalculator;

    const UGOV = await ethers.getContractFactory("UbiquityGovernance");
    uGOV = (await UGOV.deploy(manager.address)) as UbiquityGovernance;

    const debtCouponFactory = await ethers.getContractFactory("DebtCoupon");
    debtCoupon = (await debtCouponFactory.deploy(await admin.getAddress())) as DebtCoupon;
  });
  describe("BondingShare", () => {
    it("Set should work", async () => {
      bondingShare = (await (await ethers.getContractFactory("BondingShare")).connect(admin).deploy(await admin.getAddress())) as BondingShare;

      await manager.connect(admin).setBondingShareAddress(bondingShare.address);
      const bondingShareAddr = BigNumber.from(await ethers.provider.getStorageAt(manager.address, 6)).toHexString();
      expect(bondingShare.address.toLowerCase()).to.equal(bondingShareAddr.toLowerCase());
    });
  });
  describe("sushiSwapPoolAddress", () => {
    it("Set should revert if uAD is not set", async () => {
      const sushiSwapPoolFactory = await ethers.getContractFactory("SushiSwapPool");
      await expect(sushiSwapPoolFactory.deploy(manager.address)).to.be.revertedWith("Dollar address not set");
    });
    it("Set should revert if uGOV is not set", async () => {
      await manager.connect(admin).setDollarTokenAddress(uAD.address);
      const sushiSwapPoolFactory = await ethers.getContractFactory("SushiSwapPool");
      await expect(sushiSwapPoolFactory.deploy(manager.address)).to.be.revertedWith("uGOV Address not set");
    });
    it("Set should work", async () => {
      await manager.connect(admin).setGovernanceTokenAddress(uGOV.address);
      await manager.connect(admin).setDollarTokenAddress(uAD.address);

      const sushiSwapPoolFactory = await ethers.getContractFactory("SushiSwapPool");
      const sushiSwapPool = (await sushiSwapPoolFactory.deploy(manager.address)) as SushiSwapPool;

      await manager.connect(admin).setSushiSwapPoolAddress(sushiSwapPool.address);

      const sushiSwapPoolAddr = BigNumber.from(await ethers.provider.getStorageAt(manager.address, 12)).toHexString();

      expect(sushiSwapPool.address.toLowerCase()).to.equal(sushiSwapPoolAddr.toLowerCase());
    });
  });
  describe("uADTokenAddress", () => {
    it("Set should work", async () => {
      await manager.connect(admin).setDollarTokenAddress(uAD.address);

      const uADTokenAddr = BigNumber.from(await ethers.provider.getStorageAt(manager.address, 3)).toHexString();

      expect(uAD.address.toLowerCase()).to.equal(uADTokenAddr.toLowerCase());
    });
  });

  describe("uGOVTokenAddress", () => {
    it("Set should work", async () => {
      await manager.connect(admin).setGovernanceTokenAddress(uGOV.address);

      const uGOVTokenAddr = BigNumber.from(await ethers.provider.getStorageAt(manager.address, 11)).toHexString();

      expect(uGOV.address.toLowerCase()).to.equal(uGOVTokenAddr.toLowerCase());
    });
  });
  describe("uARTokenAddress", () => {
    it("Set should work", async () => {
      await manager.connect(admin).setuARTokenAddress(uAR.address);

      const uARTokenAddr = BigNumber.from(await ethers.provider.getStorageAt(manager.address, 15)).toHexString();

      expect(uAR.address.toLowerCase()).to.equal(uARTokenAddr.toLowerCase());
    });
  });
  describe("uarForDollarsCalculator", () => {
    it("Set should work", async () => {
      await manager.connect(admin).setUARCalculatorAddress(uarForDollarsCalculator.address);

      const uarForDollarsCalculatorAddr = BigNumber.from(await ethers.provider.getStorageAt(manager.address, 16)).toHexString();

      expect(uarForDollarsCalculator.address.toLowerCase()).to.equal(uarForDollarsCalculatorAddr.toLowerCase());
    });
  });

  describe("debtCouponAddress", () => {
    it("Set should work", async () => {
      await manager.connect(admin).setDebtCouponAddress(debtCoupon.address);

      const debtCouponAddr = BigNumber.from(await ethers.provider.getStorageAt(manager.address, 2)).toHexString();

      expect(debtCoupon.address.toLowerCase()).to.equal(debtCouponAddr.toLowerCase());
    });
  });
  describe("StablePool", () => {
    beforeEach(async () => {
      await network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [curveWhaleAddress],
      });
      const curveWhale = ethers.provider.getSigner(curveWhaleAddress);
      const crvToken = (await ethers.getContractAt("ERC20", curve3CrvToken)) as ERC20;
      await crvToken.connect(curveWhale).transfer(manager.address, ethers.utils.parseEther("10000"));
      // setDollarTokenAddress needed for the stable pool
      await manager.connect(admin).setDollarTokenAddress(uAD.address);
      // the uADManager needs some uAD to provide liquidity
      await uAD.connect(admin).mint(manager.address, ethers.utils.parseEther("10000"));
      await manager.connect(admin).deployStableSwapPool(curveFactory, curve3CrvBasePool, crvToken.address, 10, 4000000);
    });
    it("should deploy", async () => {
      const metaPoolAddr = await manager.stableSwapMetaPoolAddress();
      const metaPoolAddrFromStorage = BigNumber.from(await ethers.provider.getStorageAt(manager.address, 8)).toHexString();

      expect(metaPoolAddr.toLowerCase()).to.equal(metaPoolAddrFromStorage.toLowerCase());
    });
    it("should return correct price", async () => {
      const metaPoolAddr = await manager.stableSwapMetaPoolAddress();
      const metaPoolAddrFromStorage = BigNumber.from(await ethers.provider.getStorageAt(manager.address, 8)).toHexString();

      expect(metaPoolAddr.toLowerCase()).to.equal(metaPoolAddrFromStorage.toLowerCase());
    });
  });
});
