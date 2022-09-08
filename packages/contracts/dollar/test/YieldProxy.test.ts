import { BigNumber, Signer } from "ethers";
import { ethers } from "hardhat";
import { expect } from "chai";
import { YieldProxy } from "../artifacts/types/YieldProxy";
import { ERC20 } from "../artifacts/types/ERC20";
import { UbiquityAlgorithmicDollar } from "../artifacts/types/UbiquityAlgorithmicDollar";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";
import { UbiquityAutoRedeem } from "../artifacts/types/UbiquityAutoRedeem";
import { UbiquityGovernance } from "../artifacts/types/UbiquityGovernance";
import yieldProxySetup from "./YieldProxySetup";
import { IJar } from "../artifacts/types/IJar";

describe("yield Proxy", () => {
  let fifthAccount: Signer;
  let uAR: UbiquityAutoRedeem;
  let yieldProxy: YieldProxy;
  let manager: UbiquityAlgorithmicDollarManager;
  let usdcWhaleAddress: string;
  let uAD: UbiquityAlgorithmicDollar;
  let uGOV: UbiquityGovernance;
  let DAI: string;
  let USDC: string;
  let usdcToken: ERC20;
  let admin: Signer;
  let usdcWhale: Signer;
  let secondAccount: Signer;
  let thirdAccount: Signer;
  let fourthAccount: Signer;
  let treasury: Signer;
  let jarUSDCAddr: string;
  let jarYCRVLUSDaddr: string;
  let strategyYearnUsdcV2: string;
  let secondAddress: string;
  let jar: IJar;
  beforeEach(async () => {
    ({
      usdcToken,
      usdcWhale,
      admin,
      secondAccount,
      thirdAccount,
      fourthAccount,
      fifthAccount,
      treasury,
      usdcWhaleAddress,
      jarUSDCAddr,
      jarYCRVLUSDaddr,
      jar,
      uAD,
      uGOV,
      uAR,
      yieldProxy,
      DAI,
      USDC,
      manager,
      strategyYearnUsdcV2,
    } = await yieldProxySetup());
    secondAddress = await secondAccount.getAddress();
    // mint uad for whale
  });
  it("deposit should work with max yield and min deposit", async () => {
    const usdcBal = await usdcToken.balanceOf(secondAddress);
    const uadBal = await uAD.balanceOf(secondAddress);
    const ubqBal = await uGOV.balanceOf(secondAddress);
    // 1000 USDC
    const amount = ethers.utils.parseUnits("1000", 6);
    // 500 UAD which is the max
    const uadAmount = ethers.utils.parseEther("500");
    // 10000 UBQ which is the max
    const ubqAmount = ethers.utils.parseEther("10000");
    const uarBal = await uAR.balanceOf(secondAddress);
    await usdcToken.connect(secondAccount).approve(yieldProxy.address, amount);
    await uAD.connect(secondAccount).approve(yieldProxy.address, uadAmount);
    await uGOV.connect(secondAccount).approve(yieldProxy.address, ubqAmount);

    const ratio = await jar.getRatio();
    await expect(yieldProxy.connect(secondAccount).deposit(amount, uadAmount, ubqAmount)).to.emit(yieldProxy, "Deposit");
    const usdcBalAfterDeposit = await usdcToken.balanceOf(secondAddress);
    const uadBalAfterDeposit = await uAD.balanceOf(secondAddress);
    const ubqBalAfterDeposit = await uGOV.balanceOf(secondAddress);
    const uarBalAfterDeposit = await uAR.balanceOf(secondAddress);
    expect(usdcBal.sub(amount)).to.equal(usdcBalAfterDeposit);
    expect(uadBal.sub(uadAmount)).to.equal(uadBalAfterDeposit);
    expect(ubqBal.sub(ubqAmount)).to.equal(ubqBalAfterDeposit);
    expect(uarBal).to.equal(uarBalAfterDeposit);
    const infos = await yieldProxy.getInfo(secondAddress);

    const shares = await jar.balanceOf(yieldProxy.address);
    const bonusYield = 10000; // max amount
    expect(infos[0]).to.equal(amount);
    expect(infos[1]).to.equal(shares);
    expect(infos[2]).to.equal(uadAmount);
    expect(infos[3]).to.equal(ubqAmount);
    expect(infos[4]).to.equal(0);
    expect(infos[5]).to.equal(ratio);
    expect(infos[6]).to.equal(bonusYield);

    // simulate a jar yield
    await usdcToken.connect(usdcWhale).transfer(strategyYearnUsdcV2, ethers.utils.parseUnits("100000", 6));
    await jar.earn();
    const ratio2 = await jar.getRatio();
    expect(ratio2.gt(ratio)).to.be.true;
    await expect(yieldProxy.connect(secondAccount).withdrawAll()).to.emit(yieldProxy, "WithdrawAll");
    const usdcBalAfterWithdraw = await usdcToken.balanceOf(secondAddress);
    const uadBalAfterWithdraw = await uAD.balanceOf(secondAddress);
    const ubqBalAfterWithdraw = await uGOV.balanceOf(secondAddress);
    const uarBalAfterWithdraw = await uAR.balanceOf(secondAddress);
    const infos2 = await yieldProxy.getInfo(secondAddress);
    infos2.forEach((element) => {
      expect(element).to.equal(0);
    });

    const calculatedYieldInUSDC = amount.mul(ratio2).div(ratio).sub(amount);
    // we have the maximum bonus and 0% deposit fee
    expect(usdcBalAfterWithdraw).to.equal(usdcBal);
    expect(uadBalAfterWithdraw).to.equal(uadBal);
    expect(ubqBalAfterWithdraw).to.equal(ubqBal);
    // scale USDC to uAR decimals
    const usdcPrecision = BigNumber.from(1000000000000);
    const calculatedYieldInETH = calculatedYieldInUSDC.mul(usdcPrecision);
    // remove dust
    const uarBalAfterWithdrawRounded = uarBalAfterWithdraw.div(usdcPrecision).mul(usdcPrecision);

    expect(uarBalAfterWithdrawRounded).to.equal(calculatedYieldInETH.mul(2));
  });
  it("deposit should work with max yield and min deposit and extra UAD and UBQ sent", async () => {
    const usdcBal = await usdcToken.balanceOf(secondAddress);
    const uadBal = await uAD.balanceOf(secondAddress);
    const ubqBal = await uGOV.balanceOf(secondAddress);
    // 1000 USDC
    const amount = ethers.utils.parseUnits("1000", 6);
    // 500 UAD which is the max
    const uadAmount = ethers.utils.parseEther("5000");
    // 10000 UBQ which is the max
    const ubqAmount = ethers.utils.parseEther("20000");
    const uarBal = await uAR.balanceOf(secondAddress);
    await usdcToken.connect(secondAccount).approve(yieldProxy.address, amount);
    await uAD.connect(secondAccount).approve(yieldProxy.address, uadAmount);
    await uGOV.connect(secondAccount).approve(yieldProxy.address, ubqAmount);

    const ratio = await jar.getRatio();
    await expect(yieldProxy.connect(secondAccount).deposit(amount, uadAmount, ubqAmount)).to.emit(yieldProxy, "Deposit");
    const usdcBalAfterDeposit = await usdcToken.balanceOf(secondAddress);
    const uadBalAfterDeposit = await uAD.balanceOf(secondAddress);
    const ubqBalAfterDeposit = await uGOV.balanceOf(secondAddress);
    const uarBalAfterDeposit = await uAR.balanceOf(secondAddress);
    expect(usdcBal.sub(amount)).to.equal(usdcBalAfterDeposit);
    expect(uadBal.sub(uadAmount)).to.equal(uadBalAfterDeposit);
    expect(ubqBal.sub(ubqAmount)).to.equal(ubqBalAfterDeposit);
    expect(uarBal).to.equal(uarBalAfterDeposit);
    const infos = await yieldProxy.getInfo(secondAddress);

    const shares = await jar.balanceOf(yieldProxy.address);
    const bonusYield = 10000; // max amount
    expect(infos[0]).to.equal(amount);
    expect(infos[1]).to.equal(shares);
    expect(infos[2]).to.equal(uadAmount);
    expect(infos[3]).to.equal(ubqAmount);
    expect(infos[4]).to.equal(0);
    expect(infos[5]).to.equal(ratio);
    expect(infos[6]).to.equal(bonusYield);

    // simulate a jar yield
    await usdcToken.connect(usdcWhale).transfer(strategyYearnUsdcV2, ethers.utils.parseUnits("100000", 6));
    await jar.earn();
    const ratio2 = await jar.getRatio();
    expect(ratio2.gt(ratio)).to.be.true;
    await expect(yieldProxy.connect(secondAccount).withdrawAll()).to.emit(yieldProxy, "WithdrawAll");
    const usdcBalAfterWithdraw = await usdcToken.balanceOf(secondAddress);
    const uadBalAfterWithdraw = await uAD.balanceOf(secondAddress);
    const ubqBalAfterWithdraw = await uGOV.balanceOf(secondAddress);
    const uarBalAfterWithdraw = await uAR.balanceOf(secondAddress);
    const infos2 = await yieldProxy.getInfo(secondAddress);
    infos2.forEach((element) => {
      expect(element).to.equal(0);
    });

    const calculatedYieldInUSDC = amount.mul(ratio2).div(ratio).sub(amount);
    // we have the maximum bonus and 0% deposit fee
    expect(usdcBalAfterWithdraw).to.equal(usdcBal);
    expect(uadBalAfterWithdraw).to.equal(uadBal);
    expect(ubqBalAfterWithdraw).to.equal(ubqBal);
    // scale USDC to uAR decimals
    const usdcPrecision = BigNumber.from(1000000000000);
    const calculatedYieldInETH = calculatedYieldInUSDC.mul(usdcPrecision);
    // remove dust
    const uarBalAfterWithdrawRounded = uarBalAfterWithdraw.div(usdcPrecision).mul(usdcPrecision);

    expect(uarBalAfterWithdrawRounded).to.equal(calculatedYieldInETH.mul(2));
  });
  it("deposit should work with max yield and 10% deposit fee ", async () => {
    const usdcBal = await usdcToken.balanceOf(secondAddress);
    const uadBal = await uAD.balanceOf(secondAddress);
    const ubqBal = await uGOV.balanceOf(secondAddress);
    const USDCAmount = "1000";
    // 1000 USDC
    const amount = ethers.utils.parseUnits(USDCAmount, 6);
    const amountInETH = ethers.utils.parseEther(USDCAmount);
    // 500 UAD which is the max
    const uadAmount = amountInETH.div(2);
    // 0 UBQ which mean deposit fee will be 10%
    const ubqAmount = ethers.utils.parseEther("0");
    const uarBal = await uAR.balanceOf(secondAddress);
    // 10% of the deposited amount with the same decimals than the underlying token
    const expectedFee = amount.div(10);
    const expectedFeeInETH = amountInETH.div(10);
    await usdcToken.connect(secondAccount).approve(yieldProxy.address, amount);
    await uAD.connect(secondAccount).approve(yieldProxy.address, uadAmount);
    await uGOV.connect(secondAccount).approve(yieldProxy.address, ubqAmount);
    const ratio = await jar.getRatio();

    await expect(yieldProxy.connect(secondAccount).deposit(amount, uadAmount, ubqAmount)).to.emit(yieldProxy, "Deposit");
    const usdcBalAfterDeposit = await usdcToken.balanceOf(secondAddress);
    const uadBalAfterDeposit = await uAD.balanceOf(secondAddress);
    const ubqBalAfterDeposit = await uGOV.balanceOf(secondAddress);
    const uarBalAfterDeposit = await uAR.balanceOf(secondAddress);

    expect(usdcBal.sub(amount)).to.equal(usdcBalAfterDeposit);
    expect(uadBal.sub(uadAmount)).to.equal(uadBalAfterDeposit);
    expect(ubqBal.sub(ubqAmount)).to.equal(ubqBalAfterDeposit);
    expect(uarBal).to.equal(uarBalAfterDeposit);
    const infos = await yieldProxy.getInfo(secondAddress);
    const shares = await jar.balanceOf(yieldProxy.address);
    const bonusYield = 10000; // max amount

    expect(infos[0]).to.equal(amount); // token amount deposited by the user with same decimals as underlying token
    expect(infos[1]).to.equal(shares); // pickle jar shares
    expect(infos[2]).to.equal(uadAmount); // amount of uAD staked
    expect(infos[3]).to.equal(ubqAmount); // amount of UBQ staked
    expect(infos[4]).to.equal(expectedFee); // deposit fee with same decimals as underlying token
    expect(infos[5]).to.equal(ratio); // used to calculate yield
    expect(infos[6]).to.equal(bonusYield); // used to calculate bonusYield on yield in uAR

    // simulate a jar yield
    await usdcToken.connect(usdcWhale).transfer(strategyYearnUsdcV2, ethers.utils.parseUnits("100000", 6));
    await jar.earn();
    const ratio2 = await jar.getRatio();
    expect(ratio2.gt(ratio)).to.be.true;
    await expect(yieldProxy.connect(secondAccount).withdrawAll()).to.emit(yieldProxy, "WithdrawAll");
    const usdcBalAfterWithdraw = await usdcToken.balanceOf(secondAddress);
    const uadBalAfterWithdraw = await uAD.balanceOf(secondAddress);
    const ubqBalAfterWithdraw = await uGOV.balanceOf(secondAddress);
    const uarBalAfterWithdraw = await uAR.balanceOf(secondAddress);

    const infos2 = await yieldProxy.getInfo(secondAddress);
    infos2.forEach((element) => {
      expect(element).to.equal(0);
    });

    const calculatedYieldInUSDC = amount.mul(ratio2).div(ratio).sub(amount);
    // we have the maximum bonus and 10% deposit fee
    expect(usdcBalAfterWithdraw).to.equal(usdcBal.sub(expectedFee));
    expect(uadBalAfterWithdraw).to.equal(uadBal);
    expect(ubqBalAfterWithdraw).to.equal(ubqBal);
    // scale USDC to uAR decimals
    const usdcPrecision = BigNumber.from(1000000000000);
    const calculatedYieldInETH = calculatedYieldInUSDC.mul(usdcPrecision);
    // remove dust
    const uarBalAfterWithdrawRounded = uarBalAfterWithdraw.div(usdcPrecision).mul(usdcPrecision);

    expect(uarBalAfterWithdrawRounded).to.equal(calculatedYieldInETH.mul(2).add(expectedFeeInETH));
  });
  it("deposit should work with max yield and 1% reduction deposit fee ", async () => {
    const usdcBal = await usdcToken.balanceOf(secondAddress);
    const uadBal = await uAD.balanceOf(secondAddress);
    const ubqBal = await uGOV.balanceOf(secondAddress);
    const USDCAmount = "1000";
    // 1000 USDC
    const amount = ethers.utils.parseUnits(USDCAmount, 6);
    const amountInETH = ethers.utils.parseEther(USDCAmount);
    // 500 UAD which is the max
    const uadAmount = amountInETH.div(2);
    // 9000 UBQ means deposit fee will be 1% 10000 UBQ is the max and allow you to have 0% deposit fee
    const ubqAmount = ethers.utils.parseEther("9000");
    const uarBal = await uAR.balanceOf(secondAddress);
    // 1% of the deposited amount with the same decimals than the underlying token
    const expectedFee = amount.div(100);
    const expectedFeeInETH = amountInETH.div(100);
    await usdcToken.connect(secondAccount).approve(yieldProxy.address, amount);
    await uAD.connect(secondAccount).approve(yieldProxy.address, uadAmount);
    await uGOV.connect(secondAccount).approve(yieldProxy.address, ubqAmount);
    const ratio = await jar.getRatio();

    await expect(yieldProxy.connect(secondAccount).deposit(amount, uadAmount, ubqAmount)).to.emit(yieldProxy, "Deposit");
    const usdcBalAfterDeposit = await usdcToken.balanceOf(secondAddress);
    const uadBalAfterDeposit = await uAD.balanceOf(secondAddress);
    const ubqBalAfterDeposit = await uGOV.balanceOf(secondAddress);
    const uarBalAfterDeposit = await uAR.balanceOf(secondAddress);

    expect(usdcBal.sub(amount)).to.equal(usdcBalAfterDeposit);
    expect(uadBal.sub(uadAmount)).to.equal(uadBalAfterDeposit);
    expect(ubqBal.sub(ubqAmount)).to.equal(ubqBalAfterDeposit);
    expect(uarBal).to.equal(uarBalAfterDeposit);
    const infos = await yieldProxy.getInfo(secondAddress);

    const shares = await jar.balanceOf(yieldProxy.address);
    const bonusYield = 10000; // max amount

    expect(infos[0]).to.equal(amount); // token amount deposited by the user with same decimals as underlying token
    expect(infos[1]).to.equal(shares); // pickle jar shares
    expect(infos[2]).to.equal(uadAmount); // amount of uAD staked
    expect(infos[3]).to.equal(ubqAmount); // amount of UBQ staked
    expect(infos[4]).to.equal(expectedFee); // deposit fee with same decimals as underlying token
    expect(infos[5]).to.equal(ratio); // used to calculate yield
    expect(infos[6]).to.equal(bonusYield); // used to calculate bonusYield on yield in uAR

    // simulate a jar yield
    await usdcToken.connect(usdcWhale).transfer(strategyYearnUsdcV2, ethers.utils.parseUnits("100000", 6));
    await jar.earn();
    const ratio2 = await jar.getRatio();
    expect(ratio2.gt(ratio)).to.be.true;
    await expect(yieldProxy.connect(secondAccount).withdrawAll()).to.emit(yieldProxy, "WithdrawAll");
    const usdcBalAfterWithdraw = await usdcToken.balanceOf(secondAddress);
    const uadBalAfterWithdraw = await uAD.balanceOf(secondAddress);
    const ubqBalAfterWithdraw = await uGOV.balanceOf(secondAddress);
    const uarBalAfterWithdraw = await uAR.balanceOf(secondAddress);

    const infos2 = await yieldProxy.getInfo(secondAddress);
    infos2.forEach((element) => {
      expect(element).to.equal(0);
    });

    const calculatedYieldInUSDC = amount.mul(ratio2).div(ratio).sub(amount);
    // we have the maximum bonus and 10% deposit fee
    expect(usdcBalAfterWithdraw).to.equal(usdcBal.sub(expectedFee));
    expect(uadBalAfterWithdraw).to.equal(uadBal);
    expect(ubqBalAfterWithdraw).to.equal(ubqBal);
    // scale USDC to uAR decimals
    const usdcPrecision = BigNumber.from(1000000000000);
    const calculatedYieldInETH = calculatedYieldInUSDC.mul(usdcPrecision);
    // remove dust
    const uarBalAfterWithdrawRounded = uarBalAfterWithdraw.div(usdcPrecision).mul(usdcPrecision);

    expect(uarBalAfterWithdrawRounded).to.equal(calculatedYieldInETH.mul(2).add(expectedFeeInETH));
  });
  it("deposit should work with 0 extra yield and min deposit ", async () => {
    const usdcBal = await usdcToken.balanceOf(secondAddress);
    const uadBal = await uAD.balanceOf(secondAddress);
    const ubqBal = await uGOV.balanceOf(secondAddress);
    const USDCAmount = "1000";
    // 1000 USDC
    const amount = ethers.utils.parseUnits(USDCAmount, 6);
    // 0 UAD which means no extra yield
    const uadAmount = 0;
    // 10000 UBQ is the max and allow you to have 0% deposit fee
    const ubqAmount = ethers.utils.parseEther("10000");
    const uarBal = await uAR.balanceOf(secondAddress);
    const expectedFee = 0;
    const expectedFeeInETH = 0;
    await usdcToken.connect(secondAccount).approve(yieldProxy.address, amount);
    await uAD.connect(secondAccount).approve(yieldProxy.address, uadAmount);
    await uGOV.connect(secondAccount).approve(yieldProxy.address, ubqAmount);

    const ratio = await jar.getRatio();

    await expect(yieldProxy.connect(secondAccount).deposit(amount, uadAmount, ubqAmount)).to.emit(yieldProxy, "Deposit");
    const usdcBalAfterDeposit = await usdcToken.balanceOf(secondAddress);
    const uadBalAfterDeposit = await uAD.balanceOf(secondAddress);
    const ubqBalAfterDeposit = await uGOV.balanceOf(secondAddress);
    const uarBalAfterDeposit = await uAR.balanceOf(secondAddress);

    expect(usdcBal.sub(amount)).to.equal(usdcBalAfterDeposit);
    expect(uadBal.sub(uadAmount)).to.equal(uadBalAfterDeposit);
    expect(ubqBal.sub(ubqAmount)).to.equal(ubqBalAfterDeposit);
    expect(uarBal).to.equal(uarBalAfterDeposit);
    const infos = await yieldProxy.getInfo(secondAddress);

    const shares = await jar.balanceOf(yieldProxy.address);
    const bonusYield = 5000; // 50% of bonus yield in UAR which is the minimum
    expect(infos[0]).to.equal(amount); // token amount deposited by the user with same decimals as underlying token
    expect(infos[1]).to.equal(shares); // pickle jar shares
    expect(infos[2]).to.equal(uadAmount); // amount of uAD staked
    expect(infos[3]).to.equal(ubqAmount); // amount of UBQ staked
    expect(infos[4]).to.equal(expectedFee); // deposit fee with same decimals as underlying token
    expect(infos[5]).to.equal(ratio); // used to calculate yield
    expect(infos[6]).to.equal(bonusYield); // used to calculate bonusYield on yield in uAR

    // simulate a jar yield
    await usdcToken.connect(usdcWhale).transfer(strategyYearnUsdcV2, ethers.utils.parseUnits("100000", 6));
    await jar.earn();
    const ratio2 = await jar.getRatio();
    expect(ratio2.gt(ratio)).to.be.true;
    await expect(yieldProxy.connect(secondAccount).withdrawAll()).to.emit(yieldProxy, "WithdrawAll");
    const usdcBalAfterWithdraw = await usdcToken.balanceOf(secondAddress);
    const uadBalAfterWithdraw = await uAD.balanceOf(secondAddress);
    const ubqBalAfterWithdraw = await uGOV.balanceOf(secondAddress);
    const uarBalAfterWithdraw = await uAR.balanceOf(secondAddress);

    const infos2 = await yieldProxy.getInfo(secondAddress);
    infos2.forEach((element) => {
      expect(element).to.equal(0);
    });

    const calculatedYieldInUSDC = amount.mul(ratio2).div(ratio).sub(amount);
    // we have the maximum bonus and 10% deposit fee
    expect(usdcBalAfterWithdraw).to.equal(usdcBal.sub(expectedFee));
    expect(uadBalAfterWithdraw).to.equal(uadBal);
    expect(ubqBalAfterWithdraw).to.equal(ubqBal);
    // scale USDC to uAR decimals
    const usdcPrecision = BigNumber.from(1000000000000);
    const calculatedYieldInETH = calculatedYieldInUSDC.mul(usdcPrecision);
    const calculatedExtraYieldInETH = calculatedYieldInETH.div(2);
    // remove dust
    const uarBalAfterWithdrawRounded = uarBalAfterWithdraw.div(usdcPrecision).mul(usdcPrecision);

    expect(uarBalAfterWithdrawRounded).to.equal(calculatedYieldInETH.add(calculatedExtraYieldInETH).add(expectedFeeInETH));
  });
  it("deposit should work with 0 extra yield and 10% deposit fee ", async () => {
    const usdcBal = await usdcToken.balanceOf(secondAddress);
    const uadBal = await uAD.balanceOf(secondAddress);
    const ubqBal = await uGOV.balanceOf(secondAddress);
    const USDCAmount = "1000";
    // 1000 USDC
    const amount = ethers.utils.parseUnits(USDCAmount, 6);
    const amountInETH = ethers.utils.parseEther(USDCAmount);
    // 0 UAD
    const uadAmount = 0;
    const bonusYield = 5000; // min amount
    // 0 UBQ which mean deposit fee will be 10%
    const ubqAmount = ethers.utils.parseEther("0");
    const uarBal = await uAR.balanceOf(secondAddress);
    // 10% of the deposited amount with the same decimals than the underlying token
    const expectedFee = amount.div(10);
    const expectedFeeInETH = amountInETH.div(10);
    await usdcToken.connect(secondAccount).approve(yieldProxy.address, amount);
    await uAD.connect(secondAccount).approve(yieldProxy.address, uadAmount);
    await uGOV.connect(secondAccount).approve(yieldProxy.address, ubqAmount);

    const ratio = await jar.getRatio();

    await expect(yieldProxy.connect(secondAccount).deposit(amount, uadAmount, ubqAmount)).to.emit(yieldProxy, "Deposit");
    const usdcBalAfterDeposit = await usdcToken.balanceOf(secondAddress);
    const uadBalAfterDeposit = await uAD.balanceOf(secondAddress);
    const ubqBalAfterDeposit = await uGOV.balanceOf(secondAddress);
    const uarBalAfterDeposit = await uAR.balanceOf(secondAddress);

    expect(usdcBal.sub(amount)).to.equal(usdcBalAfterDeposit);
    expect(uadBal.sub(uadAmount)).to.equal(uadBalAfterDeposit);
    expect(ubqBal.sub(ubqAmount)).to.equal(ubqBalAfterDeposit);
    expect(uarBal).to.equal(uarBalAfterDeposit);
    const infos = await yieldProxy.getInfo(secondAddress);

    const shares = await jar.balanceOf(yieldProxy.address);

    expect(infos[0]).to.equal(amount); // token amount deposited by the user with same decimals as underlying token
    expect(infos[1]).to.equal(shares); // pickle jar shares
    expect(infos[2]).to.equal(uadAmount); // amount of uAD staked
    expect(infos[3]).to.equal(ubqAmount); // amount of UBQ staked
    expect(infos[4]).to.equal(expectedFee); // deposit fee with same decimals as underlying token
    expect(infos[5]).to.equal(ratio); // used to calculate yield
    expect(infos[6]).to.equal(bonusYield); // used to calculate bonusYield on yield in uAR

    // simulate a jar yield
    await usdcToken.connect(usdcWhale).transfer(strategyYearnUsdcV2, ethers.utils.parseUnits("100000", 6));
    await jar.earn();
    const ratio2 = await jar.getRatio();
    expect(ratio2.gt(ratio)).to.be.true;
    await expect(yieldProxy.connect(secondAccount).withdrawAll()).to.emit(yieldProxy, "WithdrawAll");
    const usdcBalAfterWithdraw = await usdcToken.balanceOf(secondAddress);
    const uadBalAfterWithdraw = await uAD.balanceOf(secondAddress);
    const ubqBalAfterWithdraw = await uGOV.balanceOf(secondAddress);
    const uarBalAfterWithdraw = await uAR.balanceOf(secondAddress);

    const infos2 = await yieldProxy.getInfo(secondAddress);
    infos2.forEach((element) => {
      expect(element).to.equal(0);
    });

    const calculatedYieldInUSDC = amount.mul(ratio2).div(ratio).sub(amount);
    // we have the maximum bonus and 10% deposit fee
    expect(usdcBalAfterWithdraw).to.equal(usdcBal.sub(expectedFee));
    expect(uadBalAfterWithdraw).to.equal(uadBal);
    expect(ubqBalAfterWithdraw).to.equal(ubqBal);
    // scale USDC to uAR decimals
    const usdcPrecision = BigNumber.from(1000000000000);
    const calculatedYieldInETH = calculatedYieldInUSDC.mul(usdcPrecision);
    const calculatedExtraYieldInETH = calculatedYieldInETH.div(2);
    // remove dust
    const uarBalAfterWithdrawRounded = uarBalAfterWithdraw.div(usdcPrecision).mul(usdcPrecision);

    expect(uarBalAfterWithdrawRounded).to.equal(calculatedYieldInETH.add(calculatedExtraYieldInETH).add(expectedFeeInETH));
  });
  it("deposit should work with 0 extra yield  and 1% reduction deposit fee ", async () => {
    const usdcBal = await usdcToken.balanceOf(secondAddress);
    const uadBal = await uAD.balanceOf(secondAddress);
    const ubqBal = await uGOV.balanceOf(secondAddress);
    const USDCAmount = "1000";
    // 1000 USDC
    const amount = ethers.utils.parseUnits(USDCAmount, 6);
    const amountInETH = ethers.utils.parseEther(USDCAmount);
    // 0 UAD
    const uadAmount = 0;
    const bonusYield = 5000; // min amount
    // 0 UBQ which mean deposit fee will be 10%
    const ubqAmount = ethers.utils.parseEther("9000");
    const uarBal = await uAR.balanceOf(secondAddress);
    // 1% of the deposited amount with the same decimals than the underlying token
    const expectedFee = amount.div(100);
    const expectedFeeInETH = amountInETH.div(100);
    await usdcToken.connect(secondAccount).approve(yieldProxy.address, amount);
    await uAD.connect(secondAccount).approve(yieldProxy.address, uadAmount);
    await uGOV.connect(secondAccount).approve(yieldProxy.address, ubqAmount);

    const ratio = await jar.getRatio();

    await expect(yieldProxy.connect(secondAccount).deposit(amount, uadAmount, ubqAmount)).to.emit(yieldProxy, "Deposit");
    const usdcBalAfterDeposit = await usdcToken.balanceOf(secondAddress);
    const uadBalAfterDeposit = await uAD.balanceOf(secondAddress);
    const ubqBalAfterDeposit = await uGOV.balanceOf(secondAddress);
    const uarBalAfterDeposit = await uAR.balanceOf(secondAddress);

    expect(usdcBal.sub(amount)).to.equal(usdcBalAfterDeposit);
    expect(uadBal.sub(uadAmount)).to.equal(uadBalAfterDeposit);
    expect(ubqBal.sub(ubqAmount)).to.equal(ubqBalAfterDeposit);
    expect(uarBal).to.equal(uarBalAfterDeposit);
    const infos = await yieldProxy.getInfo(secondAddress);

    const shares = await jar.balanceOf(yieldProxy.address);

    expect(infos[0]).to.equal(amount); // token amount deposited by the user with same decimals as underlying token
    expect(infos[1]).to.equal(shares); // pickle jar shares
    expect(infos[2]).to.equal(uadAmount); // amount of uAD staked
    expect(infos[3]).to.equal(ubqAmount); // amount of UBQ staked
    expect(infos[4]).to.equal(expectedFee); // deposit fee with same decimals as underlying token
    expect(infos[5]).to.equal(ratio); // used to calculate yield
    expect(infos[6]).to.equal(bonusYield); // used to calculate bonusYield on yield in uAR

    // simulate a jar yield
    await usdcToken.connect(usdcWhale).transfer(strategyYearnUsdcV2, ethers.utils.parseUnits("100000", 6));
    await jar.earn();
    const ratio2 = await jar.getRatio();
    expect(ratio2.gt(ratio)).to.be.true;
    await expect(yieldProxy.connect(secondAccount).withdrawAll()).to.emit(yieldProxy, "WithdrawAll");
    const usdcBalAfterWithdraw = await usdcToken.balanceOf(secondAddress);
    const uadBalAfterWithdraw = await uAD.balanceOf(secondAddress);
    const ubqBalAfterWithdraw = await uGOV.balanceOf(secondAddress);
    const uarBalAfterWithdraw = await uAR.balanceOf(secondAddress);

    const infos2 = await yieldProxy.getInfo(secondAddress);
    infos2.forEach((element) => {
      expect(element).to.equal(0);
    });
    const calculatedYieldInUSDC = amount.mul(ratio2).div(ratio).sub(amount);
    // we have the maximum bonus and 10% deposit fee
    expect(usdcBalAfterWithdraw).to.equal(usdcBal.sub(expectedFee));
    expect(uadBalAfterWithdraw).to.equal(uadBal);
    expect(ubqBalAfterWithdraw).to.equal(ubqBal);
    // scale USDC to uAR decimals
    const usdcPrecision = BigNumber.from(1000000000000);
    const calculatedYieldInETH = calculatedYieldInUSDC.mul(usdcPrecision);
    const calculatedExtraYieldInETH = calculatedYieldInETH.div(2);
    // remove dust
    const uarBalAfterWithdrawRounded = uarBalAfterWithdraw.div(usdcPrecision).mul(usdcPrecision);

    expect(uarBalAfterWithdrawRounded).to.equal(calculatedYieldInETH.add(calculatedExtraYieldInETH).add(expectedFeeInETH));
  });
  it("deposit should work with 55% extra yield  and 5% reduction deposit fee ", async () => {
    const usdcBal = await usdcToken.balanceOf(secondAddress);
    const uadBal = await uAD.balanceOf(secondAddress);
    const ubqBal = await uGOV.balanceOf(secondAddress);
    const USDCAmount = "1000";
    // 1000 USDC
    const amount = ethers.utils.parseUnits(USDCAmount, 6);
    const amountInETH = ethers.utils.parseEther(USDCAmount);
    const maxUADAmount = amountInETH.div(2);
    // 0 UAD = 50%,  500 UAD = 50% of amount = 100% extra yield
    // so 50 UAD = 5% of amount = 10% of max amount for extra yield = 55% extra yield
    const uadAmount = amountInETH.div(2).div(10);

    // 5000 min amount = 50 10000 max amount
    const bonusYield = BigNumber.from(5000)
      .mul(maxUADAmount.add(uadAmount).mul(ethers.utils.parseEther("100")).div(maxUADAmount))
      .div(ethers.utils.parseEther("100"));

    // 5000 UBQ which mean deposit fee will be 5%
    const ubqAmount = ethers.utils.parseEther("5000");
    const uarBal = await uAR.balanceOf(secondAddress);
    // 5% of the deposited amount with the same decimals than the underlying token
    const expectedFee = amount.div(20);
    const expectedFeeInETH = amountInETH.div(20);
    await usdcToken.connect(secondAccount).approve(yieldProxy.address, amount);
    await uAD.connect(secondAccount).approve(yieldProxy.address, uadAmount);
    await uGOV.connect(secondAccount).approve(yieldProxy.address, ubqAmount);
    const ratio = await jar.getRatio();

    await expect(yieldProxy.connect(secondAccount).deposit(amount, uadAmount, ubqAmount)).to.emit(yieldProxy, "Deposit");
    const usdcBalAfterDeposit = await usdcToken.balanceOf(secondAddress);
    const uadBalAfterDeposit = await uAD.balanceOf(secondAddress);
    const ubqBalAfterDeposit = await uGOV.balanceOf(secondAddress);
    const uarBalAfterDeposit = await uAR.balanceOf(secondAddress);

    expect(usdcBal.sub(amount)).to.equal(usdcBalAfterDeposit);
    expect(uadBal.sub(uadAmount)).to.equal(uadBalAfterDeposit);
    expect(ubqBal.sub(ubqAmount)).to.equal(ubqBalAfterDeposit);
    expect(uarBal).to.equal(uarBalAfterDeposit);
    const infos = await yieldProxy.getInfo(secondAddress);

    const shares = await jar.balanceOf(yieldProxy.address);

    expect(infos[0]).to.equal(amount); // token amount deposited by the user with same decimals as underlying token
    expect(infos[1]).to.equal(shares); // pickle jar shares
    expect(infos[2]).to.equal(uadAmount); // amount of uAD staked
    expect(infos[3]).to.equal(ubqAmount); // amount of UBQ staked
    expect(infos[4]).to.equal(expectedFee); // deposit fee with same decimals as underlying token
    expect(infos[5]).to.equal(ratio); // used to calculate yield
    expect(infos[6]).to.equal(bonusYield); // used to calculate bonusYield on yield in uAR

    // simulate a jar yield
    await usdcToken.connect(usdcWhale).transfer(strategyYearnUsdcV2, ethers.utils.parseUnits("100000", 6));
    await jar.earn();
    const ratio2 = await jar.getRatio();
    expect(ratio2.gt(ratio)).to.be.true;
    await expect(yieldProxy.connect(secondAccount).withdrawAll()).to.emit(yieldProxy, "WithdrawAll");
    const usdcBalAfterWithdraw = await usdcToken.balanceOf(secondAddress);
    const uadBalAfterWithdraw = await uAD.balanceOf(secondAddress);
    const ubqBalAfterWithdraw = await uGOV.balanceOf(secondAddress);
    const uarBalAfterWithdraw = await uAR.balanceOf(secondAddress);

    const infos2 = await yieldProxy.getInfo(secondAddress);
    infos2.forEach((element, i) => {
      expect(element).to.equal(0);
    });

    const calculatedYieldInUSDC = amount.mul(ratio2).div(ratio).sub(amount);
    // we have the maximum bonus and 10% deposit fee
    expect(usdcBalAfterWithdraw).to.equal(usdcBal.sub(expectedFee));
    expect(uadBalAfterWithdraw).to.equal(uadBal);
    expect(ubqBalAfterWithdraw).to.equal(ubqBal);
    // scale USDC to uAR decimals
    const usdcPrecision = BigNumber.from(1000000000000);
    const calculatedYieldInETH = calculatedYieldInUSDC.mul(usdcPrecision);
    // minimum extra yield is 50% but here we should have 55%
    const calculatedMinExtraYieldInETH = calculatedYieldInETH.div(2);
    // indeed we sent 10% of the maximum amount of UAD so we should get
    // 10% more of the yield
    const calculatedExtraYieldInETH = calculatedMinExtraYieldInETH.add(calculatedMinExtraYieldInETH.div(10));
    // remove dust
    const uarBalAfterWithdrawRounded = uarBalAfterWithdraw.div(usdcPrecision).mul(usdcPrecision);
    const uarBalAfterWithdrawMinusMinimumExtraYield = uarBalAfterWithdrawRounded.sub(
      expectedFeeInETH.add(calculatedYieldInETH).add(calculatedMinExtraYieldInETH)
    );
    const cent = ethers.utils.parseEther("100");
    const percentOfYield = uarBalAfterWithdrawMinusMinimumExtraYield.mul(cent).div(calculatedYieldInETH);

    expect(uarBalAfterWithdrawRounded).to.equal(calculatedYieldInETH.add(calculatedExtraYieldInETH).add(expectedFeeInETH));
  });
  it("deposit should revert if it exist", async () => {
    // 1000 USDC
    const amount = ethers.utils.parseUnits("1000", 6);
    // 500 UAD which is the max
    const uadAmount = ethers.utils.parseEther("500");
    // 10000 UBQ which is the max
    const ubqAmount = ethers.utils.parseEther("10000");
    await usdcToken.connect(secondAccount).approve(yieldProxy.address, amount);
    await uAD.connect(secondAccount).approve(yieldProxy.address, uadAmount);
    await uGOV.connect(secondAccount).approve(yieldProxy.address, ubqAmount);

    await expect(yieldProxy.connect(secondAccount).deposit(amount, uadAmount, ubqAmount)).to.emit(yieldProxy, "Deposit");

    await expect(yieldProxy.connect(secondAccount).deposit(amount, uadAmount, ubqAmount)).to.be.revertedWith("YieldProxy::DepoExist");
  });
  it("deposit should revert with 0 amount ", async () => {
    // 500 UAD which is the max
    const uadAmount = ethers.utils.parseEther("500");
    // 10000 UBQ which is the max
    const ubqAmount = ethers.utils.parseEther("10000");
    await uAD.connect(secondAccount).approve(yieldProxy.address, uadAmount);
    await uGOV.connect(secondAccount).approve(yieldProxy.address, ubqAmount);

    await expect(yieldProxy.connect(secondAccount).deposit(0, uadAmount, ubqAmount)).to.be.revertedWith("YieldProxy::amount==0");
  });
  it("withdraw should revert if no deposit", async () => {
    await expect(yieldProxy.connect(secondAccount).withdrawAll()).to.be.revertedWith("YieldProxy::amount==0");
  });
  it("setDepositFees should work", async () => {
    await yieldProxy.connect(admin).setDepositFees(500);
    expect(await yieldProxy.fees()).to.equal(500);
  });
  it("setDepositFees should revert if not admin", async () => {
    await expect(yieldProxy.connect(secondAccount).setDepositFees(56)).to.be.revertedWith("YieldProxy::!admin");
  });
  it("setUBQRate should work", async () => {
    await yieldProxy.connect(admin).setUBQRate(500);
    expect(await yieldProxy.ubqRate()).to.equal(500);
  });
  it("setUBQRate should revert if greater than max", async () => {
    await expect(yieldProxy.connect(admin).setUBQRate(ethers.utils.parseEther("10001"))).to.be.revertedWith("YieldProxy::>ubqRateMAX");
  });
  it("setUBQRate should revert if not admin", async () => {
    await expect(yieldProxy.connect(secondAccount).setUBQRate(56)).to.be.revertedWith("YieldProxy::!admin");
  });
  it("setJar should work", async () => {
    await yieldProxy.connect(admin).setJar(jarYCRVLUSDaddr);
    expect(await yieldProxy.jar()).to.equal(jarYCRVLUSDaddr);
  });
  it("setJar should revert if not admin", async () => {
    await expect(yieldProxy.connect(secondAccount).setJar(jarYCRVLUSDaddr)).to.be.revertedWith("YieldProxy::!admin");
  });
  it("setJar should revert if zero address ", async () => {
    await expect(yieldProxy.connect(admin).setJar(ethers.constants.AddressZero)).to.be.revertedWith("YieldProxy::!Jar");
  });
  it("setJar should revert if non contract address ", async () => {
    await expect(yieldProxy.connect(secondAccount).setJar(usdcWhaleAddress)).to.be.reverted;
  });
  describe("CollectableDust", () => {
    it("Admin should be able to add protocol token (CollectableDust)", async () => {
      await yieldProxy.connect(admin).addProtocolToken(USDC);
    });

    it("should revert when another account tries to add protocol token (CollectableDust)", async () => {
      await expect(yieldProxy.connect(secondAccount).addProtocolToken(USDC)).to.be.revertedWith("YieldProxy::!admin");
    });

    it("should revert when trying to add an already existing protocol token (CollectableDust)", async () => {
      await yieldProxy.connect(admin).addProtocolToken(USDC);
      await expect(yieldProxy.connect(admin).addProtocolToken(USDC)).to.be.revertedWith("collectable-dust::token-is-part-of-the-protocol");
    });

    it("should revert when another account tries to remove a protocol token (CollectableDust)", async () => {
      await expect(yieldProxy.connect(secondAccount).removeProtocolToken(USDC)).to.be.revertedWith("YieldProxy::!admin");
    });

    it("Admin should be able to remove protocol token (CollectableDust)", async () => {
      await yieldProxy.connect(admin).addProtocolToken(USDC);
      await yieldProxy.connect(admin).removeProtocolToken(USDC);
    });

    it("should revert when trying to remove token that is not a part of the protocol (CollectableDust)", async () => {
      await expect(yieldProxy.connect(admin).removeProtocolToken(USDC)).to.be.revertedWith("collectable-dust::token-not-part-of-the-protocol");
    });

    it("should emit DustSent event (CollectableDust)", async () => {
      const amount = ethers.utils.parseUnits("1000", 6);

      const uadAmount = ethers.utils.parseEther("500");
      await usdcToken.connect(secondAccount).approve(yieldProxy.address, amount);
      await uAD.connect(secondAccount).approve(yieldProxy.address, uadAmount);
      await usdcToken.connect(secondAccount).approve(yieldProxy.address, amount);
      await yieldProxy.connect(secondAccount).deposit(amount, uadAmount, 0);

      await expect(yieldProxy.connect(admin).sendDust(await admin.getAddress(), uAD.address, uadAmount))
        .to.emit(yieldProxy, "DustSent")
        .withArgs(await admin.getAddress(), uAD.address, uadAmount);
    });
    it("should revert when another account tries to remove dust from the contract (CollectableDust)", async () => {
      await expect(
        yieldProxy.connect(secondAccount).sendDust(await admin.getAddress(), await yieldProxy.ETH_ADDRESS(), ethers.utils.parseUnits("100", "gwei"))
      ).to.be.revertedWith("YieldProxy::!admin");
    });

    it("should emit ProtocolTokenAdded event (CollectableDust)", async () => {
      await expect(yieldProxy.connect(admin).addProtocolToken(DAI)).to.emit(yieldProxy, "ProtocolTokenAdded").withArgs(DAI);
    });

    it("should emit ProtocolTokenRemoved event (CollectableDust)", async () => {
      await yieldProxy.connect(admin).addProtocolToken(DAI);
      await expect(yieldProxy.connect(admin).removeProtocolToken(DAI)).to.emit(yieldProxy, "ProtocolTokenRemoved").withArgs(DAI);
    });
  });
});
