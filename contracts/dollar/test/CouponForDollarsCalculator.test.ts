import { BigNumber, Signer } from "ethers";
import { ethers } from "hardhat";
import { expect } from "chai";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";
import { MockuADToken } from "../artifacts/types/MockuADToken";
import { MockDebtCoupon } from "../artifacts/types/MockDebtCoupon";
import { DebtCouponManager } from "../artifacts/types/DebtCouponManager";
import { CouponsForDollarsCalculator } from "../artifacts/types/CouponsForDollarsCalculator";

import { calcPremium } from "./utils/calc";

describe("CouponForDollarCalculator", () => {
  let couponsForDollarsCalculator: CouponsForDollarsCalculator;
  let manager: UbiquityAlgorithmicDollarManager;
  let debtCouponMgr: DebtCouponManager;
  let debtCoupon: MockDebtCoupon;
  let admin: Signer;
  let uAD: MockuADToken;
  // let twapOracle: TWAPOracle;
  const couponLengthBlocks = 10;

  const setup = async (uADTotalSupply: BigNumber, totalDebt: BigNumber) => {
    // set uAD Mock
    const UAD = await ethers.getContractFactory("MockuADToken");
    uAD = (await UAD.deploy(uADTotalSupply)) as MockuADToken;
    await manager.connect(admin).setDollarTokenAddress(uAD.address);
    // set debt coupon Mock
    const debtCouponFactory = await ethers.getContractFactory("MockDebtCoupon");
    debtCoupon = (await debtCouponFactory.deploy(totalDebt)) as MockDebtCoupon;
    await manager.connect(admin).setDebtCouponAddress(debtCoupon.address);
  };

  beforeEach(async () => {
    // list of accounts
    [admin] = await ethers.getSigners();
    // deploy manager
    const UADMgr = await ethers.getContractFactory("UbiquityAlgorithmicDollarManager");
    manager = (await UADMgr.deploy(await admin.getAddress())) as UbiquityAlgorithmicDollarManager;

    // set coupon for dollars calculator
    const couponsForDollarsCalculatorFactory = await ethers.getContractFactory("CouponsForDollarsCalculator");
    couponsForDollarsCalculator = (await couponsForDollarsCalculatorFactory.deploy(manager.address)) as CouponsForDollarsCalculator;

    await manager.connect(admin).setCouponCalculatorAddress(couponsForDollarsCalculator.address);
    // set debt coupon Manager
    const dcManagerFactory = await ethers.getContractFactory("DebtCouponManager");
    debtCouponMgr = (await dcManagerFactory.deploy(manager.address, couponLengthBlocks)) as DebtCouponManager;
    // debtCouponMgr should have the COUPON_MANAGER_ROLE
    const COUPON_MANAGER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("COUPON_MANAGER"));
    await manager.connect(admin).grantRole(COUPON_MANAGER_ROLE, debtCouponMgr.address);
  });
  it("getCouponAmount should work without debt set to 0", async () => {
    await setup(BigNumber.from(10000000), BigNumber.from(0));
    // check that total debt is null
    const totalDebt = await debtCoupon.getTotalOutstandingDebt();
    expect(totalDebt).to.equal(0);
    const amountToExchangeForCoupon = 1;
    const couponToMint = await couponsForDollarsCalculator.getCouponAmount(amountToExchangeForCoupon);
    expect(couponToMint).to.equal(amountToExchangeForCoupon);
  });
  it("getCouponAmount should work without debt set to 0 and large supply", async () => {
    await setup(ethers.utils.parseEther("100000000"), BigNumber.from(0));
    // check that total debt is null
    const totalDebt = await debtCoupon.getTotalOutstandingDebt();
    expect(totalDebt).to.equal(0);
    const amountToExchangeForCoupon = ethers.utils.parseEther("1");
    const couponToMint = await couponsForDollarsCalculator.getCouponAmount(amountToExchangeForCoupon);
    expect(couponToMint).to.equal(amountToExchangeForCoupon);
  });
  it("getCouponAmount should work without debt set to 10%", async () => {
    const totalSupply = ethers.utils.parseEther("100000000");
    const totalDebt = ethers.utils.parseEther("10000000");
    const amountStr = ethers.utils.parseEther("42.456").toString();
    const premium = calcPremium(amountStr, "100000000", "10000000");

    await setup(totalSupply, totalDebt);
    // check that total debt is null
    const totalOutstandingDebt = await debtCoupon.getTotalOutstandingDebt();
    expect(totalOutstandingDebt).to.equal(totalDebt);
    const couponToMint = await couponsForDollarsCalculator.getCouponAmount(amountStr);
    expect(couponToMint).to.equal(premium);
  });
  it("getCouponAmount should work without debt set to 50%", async () => {
    const totalDebt = "1082743732732734394894";
    const totalSupply = "2165487465465468789789";
    const amountStr = "6546546778667854444";
    const premium = calcPremium(amountStr, totalSupply, totalDebt);
    await setup(BigNumber.from(totalSupply), BigNumber.from(totalDebt));
    // check that total debt is null
    const totalOutstandingDebt = await debtCoupon.getTotalOutstandingDebt();
    expect(totalOutstandingDebt).to.equal(totalDebt);
    const amountToExchangeForCoupon = BigNumber.from(amountStr);
    const couponToMint = await couponsForDollarsCalculator.getCouponAmount(amountToExchangeForCoupon);
    expect(couponToMint).to.equal(premium);
  });
  it("getCouponAmount should work without debt set to 99%", async () => {
    const totalDebt = "2165487465465468789789";
    const totalSupply = "2185487465465468799999";
    const amountStr = "65465456489789711112";
    const premium = calcPremium(amountStr, totalSupply, totalDebt);

    await setup(BigNumber.from(totalSupply), BigNumber.from(totalDebt));

    const totalOutstandingDebt = await debtCoupon.getTotalOutstandingDebt();
    expect(totalOutstandingDebt).to.equal(totalDebt);
    const amountToExchangeForCoupon = BigNumber.from(amountStr);

    const couponToMint = await couponsForDollarsCalculator.getCouponAmount(amountToExchangeForCoupon);

    expect(couponToMint).to.equal(premium);
  });
  it("getCouponAmount should revert with debt set to 100%", async () => {
    const totalDebt = "2165487465465468789789";
    await setup(BigNumber.from(totalDebt), BigNumber.from(totalDebt));
    const totalOutstandingDebt = await debtCoupon.getTotalOutstandingDebt();
    expect(totalOutstandingDebt).to.equal(totalDebt);
    await expect(couponsForDollarsCalculator.getCouponAmount(1)).to.revertedWith("Coupon to dollar: DEBT_TOO_HIGH");
  });
});
