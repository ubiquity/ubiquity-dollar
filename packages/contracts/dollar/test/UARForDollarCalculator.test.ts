import { Signer } from "ethers";
import { ethers } from "hardhat";
import { expect } from "chai";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";
import { UARForDollarsCalculator } from "../artifacts/types/UARForDollarsCalculator";
import { calcUARforDollar, isAmountEquivalent } from "./utils/calc";
import { DebtCoupon } from "../artifacts/types/DebtCoupon";
import { UbiquityAlgorithmicDollar } from "../artifacts/types/UbiquityAlgorithmicDollar";

describe("UARForDollarsCalculator", () => {
  let manager: UbiquityAlgorithmicDollarManager;
  let uARForDollarCalculator: UARForDollarsCalculator;
  let admin: Signer;
  let debtCoupon: DebtCoupon;
  let uAD: UbiquityAlgorithmicDollar;

  beforeEach(async () => {
    // list of accounts
    [admin] = await ethers.getSigners();
    // deploy manager
    const UADMgr = await ethers.getContractFactory("UbiquityAlgorithmicDollarManager");
    manager = (await UADMgr.deploy(await admin.getAddress())) as UbiquityAlgorithmicDollarManager;
    // set ubiquity Dollar
    const uADFactory = await ethers.getContractFactory("UbiquityAlgorithmicDollar");
    uAD = (await uADFactory.deploy(manager.address)) as UbiquityAlgorithmicDollar;
    await manager.connect(admin).setDollarTokenAddress(uAD.address);
    await uAD.mint(await admin.getAddress(), ethers.utils.parseEther("10000"));
    // set debt coupon token
    const debtCouponFactory = await ethers.getContractFactory("DebtCoupon");
    debtCoupon = (await debtCouponFactory.deploy(manager.address)) as DebtCoupon;

    await manager.connect(admin).setDebtCouponAddress(debtCoupon.address);

    // set UAR Dollar Minting Calculator
    const dollarMintingCalculatorFactory = await ethers.getContractFactory("UARForDollarsCalculator");
    uARForDollarCalculator = (await dollarMintingCalculatorFactory.deploy(manager.address)) as UARForDollarsCalculator;
  });
  it("should have coef equal 1 after deployment", async () => {
    const coef = await uARForDollarCalculator.getConstant();
    expect(coef).to.equal(ethers.utils.parseEther("1"));
    await uARForDollarCalculator.setConstant(ethers.utils.parseEther("1"));
    const coef2 = await uARForDollarCalculator.getConstant();
    expect(coef).to.equal(coef2);
    await uARForDollarCalculator.setConstant(ethers.utils.parseEther("1.00012454654"));
    const coef3 = await uARForDollarCalculator.getConstant();
    expect(coef3).to.equal(ethers.utils.parseEther("1.00012454654"));
  });
  it("should calculate correctly with coef equal 1 ", async () => {
    const blockHeight = await ethers.provider.getBlockNumber();
    const dollarToBurn = ethers.utils.parseEther("1");
    const blockHeightDebt = blockHeight - 100;
    const coef = ethers.utils.parseEther("1");
    const uARMinted = await uARForDollarCalculator.getUARAmount(dollarToBurn, blockHeightDebt);
    const calculatedUARMinted = calcUARforDollar(dollarToBurn.toString(), blockHeightDebt.toString(), blockHeight.toString(), coef.toString());
    const isPrecise = isAmountEquivalent(uARMinted.toString(), calculatedUARMinted.toString(), "0.0000000000000001");
    expect(isPrecise).to.be.true;
  });
  it("should calculate correctly with coef > 1 ", async () => {
    const blockHeight = await ethers.provider.getBlockNumber();
    const dollarToBurn = ethers.utils.parseEther("451.45");
    const blockHeightDebt = blockHeight - 24567;
    const coef = ethers.utils.parseEther("1.015");
    const uARMinted = await uARForDollarCalculator.getUARAmount(dollarToBurn, blockHeightDebt);
    const calculatedUARMinted = calcUARforDollar(dollarToBurn.toString(), blockHeightDebt.toString(), blockHeight.toString(), coef.toString());
    const isPrecise = isAmountEquivalent(uARMinted.toString(), calculatedUARMinted.toString(), "0.0001");
    expect(isPrecise).to.be.true;
  });
  it("should calculate correctly with precise coef  ", async () => {
    const blockHeight = await ethers.provider.getBlockNumber();
    const dollarToBurn = ethers.utils.parseEther("451.45");
    const blockHeightDebt = blockHeight - 24567;
    const coef = ethers.utils.parseEther("1.01546545115");
    const uARMinted = await uARForDollarCalculator.getUARAmount(dollarToBurn, blockHeightDebt);
    const calculatedUARMinted = calcUARforDollar(dollarToBurn.toString(), blockHeightDebt.toString(), blockHeight.toString(), coef.toString());
    const isPrecise = isAmountEquivalent(uARMinted.toString(), calculatedUARMinted.toString(), "0.0001");
    expect(isPrecise).to.be.true;
  });
  it("should calculate correctly with precise coef and large amount  ", async () => {
    const blockHeight = await ethers.provider.getBlockNumber();
    const dollarToBurn = ethers.utils.parseEther("24564458758451.45454564564685145");
    const blockHeightDebt = blockHeight - 24567;
    const coef = ethers.utils.parseEther("1.01546545115");
    const uARMinted = await uARForDollarCalculator.getUARAmount(dollarToBurn, blockHeightDebt);
    const calculatedUARMinted = calcUARforDollar(dollarToBurn.toString(), blockHeightDebt.toString(), blockHeight.toString(), coef.toString());
    const isPrecise = isAmountEquivalent(uARMinted.toString(), calculatedUARMinted.toString(), "0.0001");
    expect(isPrecise).to.be.true;
  });
});
