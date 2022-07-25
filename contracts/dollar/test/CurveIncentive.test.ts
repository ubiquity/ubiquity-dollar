import { ContractTransaction, Signer } from "ethers";
import { ethers, getNamedAccounts, network } from "hardhat";
import { expect } from "chai";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";
import { ERC20 } from "../artifacts/types/ERC20";
import { UbiquityAlgorithmicDollar } from "../artifacts/types/UbiquityAlgorithmicDollar";
import { DebtCoupon } from "../artifacts/types/DebtCoupon";
import { DebtCouponManager } from "../artifacts/types/DebtCouponManager";
import { TWAPOracle } from "../artifacts/types/TWAPOracle";
import { IMetaPool } from "../artifacts/types/IMetaPool";
import { CouponsForDollarsCalculator } from "../artifacts/types/CouponsForDollarsCalculator";
import { DollarMintingCalculator } from "../artifacts/types/DollarMintingCalculator";
import { UbiquityAutoRedeem } from "../artifacts/types/UbiquityAutoRedeem";
import { ExcessDollarsDistributor } from "../artifacts/types/ExcessDollarsDistributor";
import { CurveUADIncentive } from "../artifacts/types/CurveUADIncentive";
import { UbiquityGovernance } from "../artifacts/types/UbiquityGovernance";
import { swap3CRVtoUAD, swapDAItoUAD, swapUADto3CRV } from "./utils/swap";
import { calculateIncentiveAmount } from "./utils/calc";

describe("CurveIncentive", () => {
  let metaPool: IMetaPool;
  let couponsForDollarsCalculator: CouponsForDollarsCalculator;
  let manager: UbiquityAlgorithmicDollarManager;
  let debtCouponMgr: DebtCouponManager;
  let curveIncentive: CurveUADIncentive;
  let daiToken: ERC20;
  let twapOracle: TWAPOracle;
  let debtCoupon: DebtCoupon;
  let admin: Signer;
  let secondAccount: Signer;
  let operation: Signer;
  let treasury: Signer;
  let uAD: UbiquityAlgorithmicDollar;
  let uGOV: UbiquityGovernance;
  let crvToken: ERC20;
  let DAI: string;
  let curveFactory: string;
  let curve3CrvBasePool: string;
  let curve3CrvToken: string;
  let curveWhaleAddress: string;
  let daiWhaleAddress: string;
  let curveWhale: Signer;
  let dollarMintingCalculator: DollarMintingCalculator;
  let autoRedeemToken: UbiquityAutoRedeem;
  let excessDollarsDistributor: ExcessDollarsDistributor;
  const oneETH = ethers.utils.parseEther("1");

  const couponLengthBlocks = 100;
  beforeEach(async () => {
    // list of accounts
    ({ curveFactory, curve3CrvBasePool, curve3CrvToken, DAI, curveWhaleAddress, daiWhaleAddress } = await getNamedAccounts());
    [admin, secondAccount, operation, treasury] = await ethers.getSigners();

    // deploy manager
    const UADMgr = await ethers.getContractFactory("UbiquityAlgorithmicDollarManager");
    manager = (await UADMgr.deploy(await admin.getAddress())) as UbiquityAlgorithmicDollarManager;

    const UAD = await ethers.getContractFactory("UbiquityAlgorithmicDollar");
    uAD = (await UAD.deploy(manager.address)) as UbiquityAlgorithmicDollar;
    await manager.setDollarTokenAddress(uAD.address);

    // set extra token
    crvToken = (await ethers.getContractAt("ERC20", curve3CrvToken)) as ERC20;
    daiToken = (await ethers.getContractAt("ERC20", DAI)) as ERC20;
    // to deploy the stableswap pool we need 3CRV and uAD
    // kindly ask a whale to give us some 3CRV
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [curveWhaleAddress],
    });
    curveWhale = ethers.provider.getSigner(curveWhaleAddress);
    await crvToken.connect(curveWhale).transfer(manager.address, ethers.utils.parseEther("10000"));
    // just mint som uAD
    // mint 10000 uAD each for admin, manager and secondAccount
    const mintings = [await operation.getAddress(), await secondAccount.getAddress(), manager.address].map(
      async (signer): Promise<ContractTransaction> => uAD.mint(signer, ethers.utils.parseEther("10000"))
    );
    await Promise.all(mintings);

    await manager.deployStableSwapPool(curveFactory, curve3CrvBasePool, crvToken.address, 10, 4000000);
    // setup the oracle
    const metaPoolAddr = await manager.stableSwapMetaPoolAddress();
    metaPool = (await ethers.getContractAt("IMetaPool", metaPoolAddr)) as IMetaPool;

    const TWAPOracleFactory = await ethers.getContractFactory("TWAPOracle");
    twapOracle = (await TWAPOracleFactory.deploy(metaPoolAddr, uAD.address, curve3CrvToken)) as TWAPOracle;

    await manager.setTwapOracleAddress(twapOracle.address);

    // set uGOV
    const uGOVFactory = await ethers.getContractFactory("UbiquityGovernance");
    uGOV = (await uGOVFactory.deploy(manager.address)) as UbiquityGovernance;

    await manager.setGovernanceTokenAddress(uGOV.address);

    // set coupon for dollar Calculator
    const couponsForDollarsCalculatorFactory = await ethers.getContractFactory("CouponsForDollarsCalculator");
    couponsForDollarsCalculator = (await couponsForDollarsCalculatorFactory.deploy(manager.address)) as CouponsForDollarsCalculator;

    await manager.setCouponCalculatorAddress(couponsForDollarsCalculator.address);
    // set Dollar Minting Calculator
    const dollarMintingCalculatorFactory = await ethers.getContractFactory("DollarMintingCalculator");
    dollarMintingCalculator = (await dollarMintingCalculatorFactory.deploy(manager.address)) as DollarMintingCalculator;
    await manager.setDollarMintingCalculatorAddress(dollarMintingCalculator.address);

    // set debt coupon token
    const dcManagerFactory = await ethers.getContractFactory("DebtCouponManager");
    const debtCouponFactory = await ethers.getContractFactory("DebtCoupon");
    debtCoupon = (await debtCouponFactory.deploy(manager.address)) as DebtCoupon;

    await manager.setDebtCouponAddress(debtCoupon.address);
    debtCouponMgr = (await dcManagerFactory.deploy(manager.address, couponLengthBlocks)) as DebtCouponManager;

    // debtCouponMgr should have the COUPON_MANAGER role to mint debtCoupon
    const COUPON_MANAGER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("COUPON_MANAGER"));
    // debtCouponMgr should have the UBQ_MINTER_ROLE to mint uAD for debtCoupon Redeem
    const UBQ_MINTER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("UBQ_MINTER_ROLE"));
    // debtCouponMgr should have the UBQ_BURNER_ROLE to burn uAD when minting debtCoupon
    const UBQ_BURNER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("UBQ_BURNER_ROLE"));
    await manager.grantRole(COUPON_MANAGER_ROLE, debtCouponMgr.address);
    await manager.grantRole(UBQ_MINTER_ROLE, debtCouponMgr.address);
    await manager.grantRole(UBQ_BURNER_ROLE, debtCouponMgr.address);

    // Incentive
    const incentiveFactory = await ethers.getContractFactory("CurveUADIncentive");
    curveIncentive = (await incentiveFactory.deploy(manager.address)) as CurveUADIncentive;
    // curveIncentive should have the UBQ_BURNER_ROLE to burn uAD during incentive
    await manager.grantRole(UBQ_BURNER_ROLE, curveIncentive.address);

    // curveIncentive should have the UBQ_MINTER_ROLE to mint uGOV during incentive
    await manager.grantRole(UBQ_MINTER_ROLE, curveIncentive.address);
    // set the incentive contract to act upon transfer from and to the curve pool
    await manager.setIncentiveToUAD(metaPool.address, curveIncentive.address);
    // turn off  Sell Penalty
    await curveIncentive.switchSellPenalty();
    // turn off  buy incentive Penalty
    await curveIncentive.switchBuyIncentive();
    // to calculate the totalOutstanding debt we need to take into account autoRedeemToken.totalSupply
    const autoRedeemTokenFactory = await ethers.getContractFactory("UbiquityAutoRedeem");
    autoRedeemToken = (await autoRedeemTokenFactory.deploy(manager.address)) as UbiquityAutoRedeem;

    await manager.setuARTokenAddress(autoRedeemToken.address);

    // when the debtManager mint uAD it there is too much it distribute the excess to
    const excessDollarsDistributorFactory = await ethers.getContractFactory("ExcessDollarsDistributor");
    excessDollarsDistributor = (await excessDollarsDistributorFactory.deploy(manager.address)) as ExcessDollarsDistributor;

    await manager.setExcessDollarsDistributor(debtCouponMgr.address, excessDollarsDistributor.address);

    // set treasury,uGOVFund and lpReward address needed for excessDollarsDistributor
    await manager.setTreasuryAddress(await treasury.getAddress());
  });

  it("curve sell penalty should be call when swapping uAD for 3CRV when uAD <1$", async () => {
    // turn on SellPenalty
    await curveIncentive.switchSellPenalty();
    const secondAccountAdr = await secondAccount.getAddress();
    const amount = ethers.utils.parseEther("100");
    // Now that the price is under peg we sell uAD and Check that the incentive is applied
    const priceBefore = await twapOracle.consult(uAD.address);
    expect(priceBefore).to.equal(oneETH);
    const balanceLPBefore = await metaPool.balanceOf(secondAccountAdr);
    const balance3CRVBefore = await crvToken.balanceOf(secondAccountAdr);
    const balanceUADBefore = await uAD.balanceOf(secondAccountAdr);

    const amountToBeSwapped = await swapUADto3CRV(metaPool, uAD, amount, secondAccount);
    const priceAfter = await twapOracle.consult(uAD.address);
    expect(priceAfter).to.be.lt(priceBefore);
    const balanceLPAfter = await metaPool.balanceOf(secondAccountAdr);
    const balance3CRVAfter = await crvToken.balanceOf(secondAccountAdr);
    const balanceUADAfter = await uAD.balanceOf(secondAccountAdr);
    const penalty = calculateIncentiveAmount(amount.toString(), priceAfter.toString());
    // we have lost all the uAD
    expect(balanceUADBefore.sub(amount).sub(penalty)).to.equal(balanceUADAfter);
    expect(balanceLPBefore).to.equal(balanceLPAfter);
    //
    expect(balance3CRVBefore.add(amountToBeSwapped)).to.equal(balance3CRVAfter);
  });
  it("curve buy Incentive should be call when swapping  3CRV for uAD  when uAD <1$", async () => {
    // turn on  buy incentive Penalty
    await curveIncentive.switchBuyIncentive();
    const secondAccountAdr = await secondAccount.getAddress();
    // get some 3crv token from our beloved whale
    await crvToken.connect(curveWhale).transfer(secondAccountAdr, ethers.utils.parseEther("1000"));

    // Now that the price is under peg we sell uAD and Check that the incentive is applied
    const priceBefore = await twapOracle.consult(uAD.address);
    expect(priceBefore).to.equal(oneETH);
    const balanceLPBefore = await metaPool.balanceOf(secondAccountAdr);
    const balance3CRVBefore = await crvToken.balanceOf(secondAccountAdr);
    const balanceUADBefore = await uAD.balanceOf(secondAccountAdr);
    const balanceUgovBefore = await uGOV.balanceOf(secondAccountAdr);
    // swap
    const amountToBeSwapped = await swap3CRVtoUAD(metaPool, crvToken, ethers.utils.parseEther("1000"), secondAccount);
    const priceAfter = await twapOracle.consult(uAD.address);
    expect(priceAfter).to.be.lt(priceBefore);
    const balanceLPAfter = await metaPool.balanceOf(secondAccountAdr);
    const balance3CRVAfter = await crvToken.balanceOf(secondAccountAdr);
    const balanceUgovAfter = await uGOV.balanceOf(secondAccountAdr);
    const balanceUADAfter = await uAD.balanceOf(secondAccountAdr);

    const incentive = calculateIncentiveAmount(amountToBeSwapped.toString(), priceAfter.toString());
    // we minted the right amount of uGOV
    expect(balanceUgovBefore.add(incentive)).to.equal(balanceUgovAfter);
    // we have more uAD
    expect(balanceUADBefore.add(amountToBeSwapped)).to.equal(balanceUADAfter);
    expect(balanceLPBefore).to.equal(balanceLPAfter);
    // we have less 3CRV
    expect(balance3CRVBefore.sub(ethers.utils.parseEther("1000"))).to.equal(balance3CRVAfter);
  });
  it("curve buy Incentive should be call when swapping  underlying for uAD when uAD <1$", async () => {
    // turn on  buy  Incentive
    await curveIncentive.switchBuyIncentive();
    const secondAccountAdr = await secondAccount.getAddress();
    const amount = ethers.utils.parseEther("0.45678");
    // get some dai token from our beloved whale
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [daiWhaleAddress],
    });
    const daiWhale = ethers.provider.getSigner(daiWhaleAddress);
    await daiToken.connect(daiWhale).transfer(secondAccountAdr, amount);
    // Now that the price is under peg we sell uAD and Check that the incentive is applied
    const priceBefore = await twapOracle.consult(uAD.address);
    expect(priceBefore).to.equal(oneETH);
    const balanceLPBefore = await metaPool.balanceOf(secondAccountAdr);
    const balanceDAIBefore = await daiToken.balanceOf(secondAccountAdr);
    const balanceUADBefore = await uAD.balanceOf(secondAccountAdr);
    const balanceUgovBefore = await uGOV.balanceOf(secondAccountAdr);
    const amountToBeSwapped = await swapDAItoUAD(metaPool, daiToken, amount, secondAccount);
    const priceAfter = await twapOracle.consult(uAD.address);
    expect(priceAfter).to.be.lt(priceBefore);
    const balanceLPAfter = await metaPool.balanceOf(secondAccountAdr);
    const balanceDAIAfter = await daiToken.balanceOf(secondAccountAdr);
    const balanceUgovAfter = await uGOV.balanceOf(secondAccountAdr);
    const balanceUADAfter = await uAD.balanceOf(secondAccountAdr);

    const incentive = calculateIncentiveAmount(amountToBeSwapped.toString(), priceAfter.toString());

    // we minted the right amount of uGOV
    // when swapping for underlying token the exchange_underlying is not precise
    const expectedUgov = balanceUgovBefore.add(incentive);
    expect(balanceUgovAfter).to.be.lt(expectedUgov);
    expect(balanceUgovAfter).to.be.gt(expectedUgov.mul(9999).div(10000));
    // we have more uAD
    const expectedUAD = balanceUADBefore.add(amountToBeSwapped);
    expect(balanceUADAfter).to.be.lt(expectedUAD);
    expect(balanceUADAfter).to.be.gt(expectedUAD.mul(9999).div(10000));
    expect(balanceLPBefore).to.equal(balanceLPAfter);
    // we have less dai
    expect(balanceDAIBefore.sub(amount)).to.equal(balanceDAIAfter);
  });
  it("setting UAD Incentive should emit an event", async () => {
    await expect(manager.setIncentiveToUAD(uGOV.address, curveIncentive.address))
      .to.emit(uAD, "IncentiveContractUpdate")
      .withArgs(uGOV.address, curveIncentive.address);
  });
  it("curve buy Incentive should not be call when receiver is exempt", async () => {
    // turn on  buy incentive Penalty
    await curveIncentive.switchBuyIncentive();
    const secondAccountAdr = await secondAccount.getAddress();
    // get some 3crv token from our beloved whale
    await crvToken.connect(curveWhale).transfer(secondAccountAdr, ethers.utils.parseEther("1000"));

    // exempt second accountr
    await expect(curveIncentive.setExemptAddress(secondAccountAdr, true)).to.emit(curveIncentive, "ExemptAddressUpdate").withArgs(secondAccountAdr, true);

    // Now that the price is under peg we sell uAD and Check that the incentive is applied
    const priceBefore = await twapOracle.consult(uAD.address);
    expect(priceBefore).to.equal(oneETH);
    const balanceLPBefore = await metaPool.balanceOf(secondAccountAdr);
    const balance3CRVBefore = await crvToken.balanceOf(secondAccountAdr);
    const balanceUADBefore = await uAD.balanceOf(secondAccountAdr);
    const balanceUgovBefore = await uGOV.balanceOf(secondAccountAdr);
    const metaPoolBalanceUADBefore = await uAD.balanceOf(metaPool.address);
    // swap
    const amountToBeSwapped = await swap3CRVtoUAD(metaPool, crvToken, ethers.utils.parseEther("1000"), secondAccount);
    const priceAfter = await twapOracle.consult(uAD.address);
    expect(priceAfter).to.be.lt(priceBefore);
    const balanceLPAfter = await metaPool.balanceOf(secondAccountAdr);
    const balance3CRVAfter = await crvToken.balanceOf(secondAccountAdr);
    const balanceUgovAfter = await uGOV.balanceOf(secondAccountAdr);
    const balanceUADAfter = await uAD.balanceOf(secondAccountAdr);
    const metaPoolBalanceUADAfter = await uAD.balanceOf(metaPool.address);

    // we minted the right wmount of uGOV
    expect(balanceUgovBefore).to.equal(balanceUgovAfter);
    // we have more uAD
    expect(balanceUADBefore.add(amountToBeSwapped)).to.equal(balanceUADAfter);
    expect(metaPoolBalanceUADAfter.add(amountToBeSwapped)).to.equal(metaPoolBalanceUADBefore);
    expect(balanceLPBefore).to.equal(balanceLPAfter);
    // we have less 3CRV
    expect(balance3CRVBefore.sub(ethers.utils.parseEther("1000"))).to.equal(balance3CRVAfter);
  });
  it("curve sell penalty should not be call when sender is exempt", async () => {
    // turn on BuyIncentive
    await curveIncentive.switchSellPenalty();
    const secondAccountAdr = await secondAccount.getAddress();
    // exempt second accountr
    await expect(curveIncentive.setExemptAddress(secondAccountAdr, true)).to.emit(curveIncentive, "ExemptAddressUpdate").withArgs(secondAccountAdr, true);

    const amount = ethers.utils.parseEther("100");
    // Now that the price is under peg we sell uAD and Check that the incentive is applied
    const priceBefore = await twapOracle.consult(uAD.address);
    expect(priceBefore).to.equal(oneETH);
    const balanceLPBefore = await metaPool.balanceOf(secondAccountAdr);
    const balance3CRVBefore = await crvToken.balanceOf(secondAccountAdr);
    const balanceUADBefore = await uAD.balanceOf(secondAccountAdr);

    const amountToBeSwapped = await swapUADto3CRV(metaPool, uAD, amount, secondAccount);
    const priceAfter = await twapOracle.consult(uAD.address);
    expect(priceAfter).to.be.lt(priceBefore);
    const balanceLPAfter = await metaPool.balanceOf(secondAccountAdr);
    const balance3CRVAfter = await crvToken.balanceOf(secondAccountAdr);
    const balanceUADAfter = await uAD.balanceOf(secondAccountAdr);

    // we have lost all the uAD
    expect(balanceUADBefore.sub(amount)).to.equal(balanceUADAfter);
    expect(balanceLPBefore).to.equal(balanceLPAfter);
    //
    expect(balance3CRVBefore.add(amountToBeSwapped)).to.equal(balance3CRVAfter);
  });
  it("curve sell penalty should revert if not enough uAD to slash", async () => {
    // turn on SellPenalty
    await curveIncentive.switchSellPenalty();
    const secondAccountAdr = await secondAccount.getAddress();
    const balanceUADBefore = await uAD.balanceOf(secondAccountAdr);

    // Now that the price is under peg we sell uAD and Check that the incentive is applied
    const priceBefore = await twapOracle.consult(uAD.address);
    expect(priceBefore).to.equal(oneETH);
    const balanceLPBefore = await metaPool.balanceOf(secondAccountAdr);
    const balance3CRVBefore = await crvToken.balanceOf(secondAccountAdr);

    const metaPoolBalanceUADBefore = await uAD.balanceOf(metaPool.address);

    // We will swap all the balance which is not possible because at the end
    // of the transfer there will be no more uAD to take as a penalty

    const amountToBeSwapped = await metaPool["get_dy(int128,int128,uint256)"](0, 1, balanceUADBefore);
    const expectedMin3CRV = amountToBeSwapped.div(100).mul(99);

    // signer need to approve metaPool for sending its coin
    await uAD.connect(secondAccount).approve(metaPool.address, balanceUADBefore);
    // secondAccount swap   3CRV=> x uAD
    await expect(metaPool.connect(secondAccount)["exchange(int128,int128,uint256,uint256)"](0, 1, balanceUADBefore, expectedMin3CRV)).to.be.reverted;

    const priceAfter = await twapOracle.consult(uAD.address);
    expect(priceAfter).to.equal(priceBefore);
    const balanceLPAfter = await metaPool.balanceOf(secondAccountAdr);
    const balance3CRVAfter = await crvToken.balanceOf(secondAccountAdr);
    const balanceUADAfter = await uAD.balanceOf(secondAccountAdr);
    const metaPoolBalanceUADAfter = await uAD.balanceOf(metaPool.address);

    // no balance has changed
    expect(balanceUADBefore).to.equal(balanceUADAfter);
    expect(balanceLPBefore).to.equal(balanceLPAfter);
    expect(metaPoolBalanceUADBefore).to.equal(metaPoolBalanceUADAfter);
    expect(balance3CRVBefore).to.equal(balance3CRVAfter);
  });
});
