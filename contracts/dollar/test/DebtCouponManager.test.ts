import { BigNumber, ContractTransaction, Signer } from "ethers";
import { ethers, getNamedAccounts, network } from "hardhat";
import { expect } from "chai";
import { SushiSwapPool } from "../artifacts/types/SushiSwapPool";
import { UbiquityGovernance } from "../artifacts/types/UbiquityGovernance";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";
import { ERC20 } from "../artifacts/types/ERC20";
import { UbiquityAlgorithmicDollar } from "../artifacts/types/UbiquityAlgorithmicDollar";
import { DebtCoupon } from "../artifacts/types/DebtCoupon";
import { DebtCouponManager } from "../artifacts/types/DebtCouponManager";
import { TWAPOracle } from "../artifacts/types/TWAPOracle";
import { IMetaPool } from "../artifacts/types/IMetaPool";
import { CouponsForDollarsCalculator } from "../artifacts/types/CouponsForDollarsCalculator";
import { UARForDollarsCalculator } from "../artifacts/types/UARForDollarsCalculator";
import { UbiquityAutoRedeem } from "../artifacts/types/UbiquityAutoRedeem";
import { DollarMintingCalculator } from "../artifacts/types/DollarMintingCalculator";
import { ExcessDollarsDistributor } from "../artifacts/types/ExcessDollarsDistributor";
import { IUniswapV2Router02 } from "../artifacts/types/IUniswapV2Router02";
import { calcPercentage, calcPremium, calcUARforDollar } from "./utils/calc";
import { swap3CRVtoUAD, swapUADto3CRV } from "./utils/swap";
import { mineNBlock, resetFork } from "./utils/hardhatNode";

describe("DebtCouponManager", () => {
  let metaPool: IMetaPool;
  let couponsForDollarsCalculator: CouponsForDollarsCalculator;
  let manager: UbiquityAlgorithmicDollarManager;
  let debtCouponMgr: DebtCouponManager;
  let twapOracle: TWAPOracle;
  let debtCoupon: DebtCoupon;
  let admin: Signer;
  let secondAccount: Signer;
  let thirdAccount: Signer;
  let treasury: Signer;
  let lpReward: Signer;
  let uAD: UbiquityAlgorithmicDollar;
  let uGOV: UbiquityGovernance;
  let uAR: UbiquityAutoRedeem;
  let crvToken: ERC20;
  let curveFactory: string;
  let curve3CrvBasePool: string;
  let curve3CrvToken: string;
  let curveWhaleAddress: string;
  let curveWhale: Signer;
  let dollarMintingCalculator: DollarMintingCalculator;
  let uarForDollarsCalculator: UARForDollarsCalculator;
  let excessDollarsDistributor: ExcessDollarsDistributor;
  const routerAdr = "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F"; // SushiV2Router02
  let router: IUniswapV2Router02;
  const oneETH = ethers.utils.parseEther("1");

  const deployUADUGOVSushiPool = async (signer: Signer): Promise<void> => {
    const signerAdr = await signer.getAddress();
    // need some uGOV to provide liquidity
    await uGOV.mint(signerAdr, ethers.utils.parseEther("1000"));
    // add liquidity to the pair uAD-UGOV 1 UGOV = 10 UAD
    const blockBefore = await ethers.provider.getBlock(await ethers.provider.getBlockNumber());
    // must allow to transfer token
    await uAD.connect(signer).approve(routerAdr, ethers.utils.parseEther("10000"));
    await uGOV.connect(signer).approve(routerAdr, ethers.utils.parseEther("1000"));
    await router
      .connect(signer)
      .addLiquidity(
        uAD.address,
        uGOV.address,
        ethers.utils.parseEther("10000"),
        ethers.utils.parseEther("1000"),
        ethers.utils.parseEther("9900"),
        ethers.utils.parseEther("990"),
        signerAdr,
        blockBefore.timestamp + 100
      );

    const sushiFactory = await ethers.getContractFactory("SushiSwapPool");
    const sushiUGOVPool = (await sushiFactory.deploy(manager.address)) as SushiSwapPool;
    await manager.setSushiSwapPoolAddress(sushiUGOVPool.address);
  };
  const couponLengthBlocks = 100;
  beforeEach(async () => {
    // list of accounts
    ({ curveFactory, curve3CrvBasePool, curve3CrvToken, curveWhaleAddress } = await getNamedAccounts());
    [admin, secondAccount, thirdAccount, treasury, lpReward] = await ethers.getSigners();
    await resetFork(12592661);
    router = (await ethers.getContractAt("IUniswapV2Router02", routerAdr)) as IUniswapV2Router02;

    // deploy manager
    const UADMgr = await ethers.getContractFactory("UbiquityAlgorithmicDollarManager");
    manager = (await UADMgr.deploy(await admin.getAddress())) as UbiquityAlgorithmicDollarManager;

    const UAD = await ethers.getContractFactory("UbiquityAlgorithmicDollar");
    uAD = (await UAD.deploy(manager.address)) as UbiquityAlgorithmicDollar;
    await manager.connect(admin).setDollarTokenAddress(uAD.address);
    const uGOVFactory = await ethers.getContractFactory("UbiquityGovernance");
    uGOV = (await uGOVFactory.deploy(manager.address)) as UbiquityGovernance;
    await manager.setGovernanceTokenAddress(uGOV.address);

    // set twap Oracle Address
    crvToken = (await ethers.getContractAt("ERC20", curve3CrvToken)) as ERC20;
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
    const mintings = [await secondAccount.getAddress(), await thirdAccount.getAddress(), manager.address].map(
      async (signer): Promise<ContractTransaction> => uAD.connect(admin).mint(signer, ethers.utils.parseEther("10000"))
    );
    await Promise.all(mintings);
    await manager.connect(admin).deployStableSwapPool(curveFactory, curve3CrvBasePool, crvToken.address, 10, 4000000);
    // setup the oracle
    const metaPoolAddr = await manager.stableSwapMetaPoolAddress();
    metaPool = (await ethers.getContractAt("IMetaPool", metaPoolAddr)) as IMetaPool;

    const TWAPOracleFactory = await ethers.getContractFactory("TWAPOracle");
    twapOracle = (await TWAPOracleFactory.deploy(metaPoolAddr, uAD.address, curve3CrvToken)) as TWAPOracle;
    await manager.connect(admin).setTwapOracleAddress(twapOracle.address);
    // set uAR for dollar Calculator
    const UARForDollarsCalculatorFactory = await ethers.getContractFactory("UARForDollarsCalculator");
    uarForDollarsCalculator = (await UARForDollarsCalculatorFactory.deploy(manager.address)) as UARForDollarsCalculator;

    await manager.connect(admin).setUARCalculatorAddress(uarForDollarsCalculator.address);

    // set coupon for dollar Calculator
    const couponsForDollarsCalculatorFactory = await ethers.getContractFactory("CouponsForDollarsCalculator");
    couponsForDollarsCalculator = (await couponsForDollarsCalculatorFactory.deploy(manager.address)) as CouponsForDollarsCalculator;
    await manager.connect(admin).setCouponCalculatorAddress(couponsForDollarsCalculator.address);
    // set Dollar Minting Calculator
    const dollarMintingCalculatorFactory = await ethers.getContractFactory("DollarMintingCalculator");
    dollarMintingCalculator = (await dollarMintingCalculatorFactory.deploy(manager.address)) as DollarMintingCalculator;
    await manager.connect(admin).setDollarMintingCalculatorAddress(dollarMintingCalculator.address);

    // set debt coupon token
    const dcManagerFactory = await ethers.getContractFactory("DebtCouponManager");
    const debtCouponFactory = await ethers.getContractFactory("DebtCoupon");
    debtCoupon = (await debtCouponFactory.deploy(manager.address)) as DebtCoupon;

    await manager.connect(admin).setDebtCouponAddress(debtCoupon.address);
    debtCouponMgr = (await dcManagerFactory.deploy(manager.address, couponLengthBlocks)) as DebtCouponManager;

    // debtCouponMgr should have the COUPON_MANAGER role to mint debtCoupon
    const COUPON_MANAGER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("COUPON_MANAGER"));
    // debtCouponMgr should have the UBQ_MINTER_ROLE to mint uAD for debtCoupon Redeem
    const UBQ_MINTER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("UBQ_MINTER_ROLE"));
    // debtCouponMgr should have the UBQ_BURNER_ROLE to burn uAD when minting debtCoupon
    const UBQ_BURNER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("UBQ_BURNER_ROLE"));
    await manager.connect(admin).grantRole(COUPON_MANAGER_ROLE, debtCouponMgr.address);
    await manager.connect(admin).grantRole(UBQ_MINTER_ROLE, debtCouponMgr.address);
    await manager.connect(admin).grantRole(UBQ_BURNER_ROLE, debtCouponMgr.address);

    // to calculate the totalOutstanding debt we need to take into account autoRedeemToken.totalSupply
    const uARFactory = await ethers.getContractFactory("UbiquityAutoRedeem");
    uAR = (await uARFactory.deploy(manager.address)) as UbiquityAutoRedeem;
    await manager.setuARTokenAddress(uAR.address);

    // when the debtManager mint uAD it there is too much it distribute the excess to
    const excessDollarsDistributorFactory = await ethers.getContractFactory("ExcessDollarsDistributor");
    excessDollarsDistributor = (await excessDollarsDistributorFactory.deploy(manager.address)) as ExcessDollarsDistributor;

    await manager.connect(admin).setExcessDollarsDistributor(debtCouponMgr.address, excessDollarsDistributor.address);

    // set treasury,uGOVFund and lpReward address needed for excessDollarsDistributor
    await manager.connect(admin).setTreasuryAddress(await treasury.getAddress());

    await manager.connect(admin).setBondingContractAddress(await lpReward.getAddress());
    await deployUADUGOVSushiPool(thirdAccount);
  });
  it("exchangeDollarsForUAR should work", async () => {
    const pool0bal = await metaPool.balances(0);
    const pool1bal = await metaPool.balances(1);
    expect(pool0bal).to.equal(ethers.utils.parseEther("10000"));
    expect(pool1bal).to.equal(ethers.utils.parseEther("10000"));
    // remove liquidity one coin 3CRV only so that uAD will be worth less
    const admBalance = await metaPool.balanceOf(await admin.getAddress());
    // calculation to withdraw 1e18 LP token
    // Calculate the amount received when withdrawing and unwrapping in a single coin.
    // Useful for setting _max_burn_amount when calling remove_liquidity_one_coin.
    const lpTo3CRV = await metaPool["calc_withdraw_one_coin(uint256,int128)"](oneETH, 1);
    const expected = lpTo3CRV.div(100).mul(99);
    // approve metapool to burn LP on behalf of admin
    await metaPool.approve(metaPool.address, admBalance);

    // Withdraw a single asset from the pool.
    await metaPool["remove_liquidity_one_coin(uint256,int128,uint256)"](oneETH, 1, expected);

    await twapOracle.update();
    // Price must be below 1 to mint coupons
    const uADPrice = await twapOracle.consult(uAD.address);
    expect(uADPrice).to.be.lt(oneETH);
    // check that total debt is null
    const totalDebt = await debtCoupon.getTotalOutstandingDebt();
    expect(totalDebt).to.equal(0);
    // launch it once to initialize the debt cycle so that getUARReturnedForDollars
    // can give us accurate result
    const secondAccountAdr = await secondAccount.getAddress();
    await expect(debtCouponMgr.connect(secondAccount).exchangeDollarsForUAR(1))
      .to.emit(uAR, "Transfer")
      .withArgs(ethers.constants.AddressZero, secondAccountAdr, 1);

    const amountToExchangeForCoupon = oneETH;

    const balanceBefore = await uAD.balanceOf(secondAccountAdr);

    // approve debtCouponManager to burn user's token
    await uAD.connect(secondAccount).approve(debtCouponMgr.address, amountToExchangeForCoupon);
    const lastBlock = await ethers.provider.getBlock(await ethers.provider.getBlockNumber());

    const blockHeightDebt = await debtCouponMgr.blockHeightDebt();
    const calculatedCouponToMint = calcUARforDollar(
      amountToExchangeForCoupon.toString(),
      blockHeightDebt.toString(),
      (lastBlock.number + 1).toString(),
      ethers.utils.parseEther("1").toString()
    );

    const expiryBlock = lastBlock.number + 1 + couponLengthBlocks;
    const secondAccUARBalBefore = await uAR.balanceOf(secondAccountAdr);

    await expect(debtCouponMgr.connect(secondAccount).exchangeDollarsForUAR(amountToExchangeForCoupon)).to.emit(uAR, "Transfer");

    const balanceAfter = await uAD.balanceOf(secondAccountAdr);

    expect(balanceBefore.sub(balanceAfter).sub(amountToExchangeForCoupon)).to.equal(0);
    // check that we have a debt coupon with correct premium
    const secondAccUARBalAfter = await uAR.balanceOf(secondAccountAdr);
    //  const debtCoupons = secondAccUARBalAfter.sub(secondAccUARBalBefore);
    expect(secondAccUARBalAfter.sub(secondAccUARBalBefore).sub(calculatedCouponToMint).toNumber()).to.be.lessThan(100);

    // check outstanding debt now
    const uarTotalSupply = await uAR.totalSupply();
    expect(uarTotalSupply).to.equal(secondAccUARBalAfter);

    // Price must be above 1 to redeem coupon
    // we previously removed 3CRV from the pool meaning uAD is <1$ because
    // we have more uAD than 3CRV. In order to make uAD >1$ we will swap 3CRV
    // for uAD.
    // Note that we previously burnt uAD but as we get the price from curve the
    // uAD burnt didn't affect the price
    const whale3CRVBalanceBeforeSwap = await crvToken.balanceOf(curveWhaleAddress);
    const CRVAmountToSwap = ethers.utils.parseEther("3000");

    // Exchange (swap)
    let dy3CRVtouAD = await swap3CRVtoUAD(metaPool, crvToken, CRVAmountToSwap.sub(BigNumber.from(1)), curveWhale);

    await twapOracle.update();
    const dy3CRVtouAD2 = await swap3CRVtoUAD(metaPool, crvToken, BigNumber.from(1), curveWhale);
    dy3CRVtouAD = dy3CRVtouAD.add(dy3CRVtouAD2);
    await twapOracle.update();
    const whale3CRVBalance = await crvToken.balanceOf(curveWhaleAddress);
    const whaleuADBalance = await uAD.balanceOf(curveWhaleAddress);

    expect(whaleuADBalance).to.equal(dy3CRVtouAD);
    expect(whale3CRVBalance).to.equal(whale3CRVBalanceBeforeSwap.sub(CRVAmountToSwap));

    await twapOracle.update();
    const uADPriceAfterSwap = await twapOracle.consult(uAD.address);
    expect(uADPriceAfterSwap).to.be.gt(oneETH);

    // now we can redeem the coupon
    // debtCouponMgr uad balance should be empty
    let debtUADBalance = await uAD.balanceOf(debtCouponMgr.address);
    expect(debtUADBalance).to.equal(0);
    const userUADBalanceBeforeRedeem = await uAD.balanceOf(secondAccountAdr);
    const mintableUAD = await dollarMintingCalculator.getDollarsToMint();
    const excessUAD = mintableUAD.sub(uarTotalSupply);
    const totalSupply = await uAD.totalSupply();

    expect(mintableUAD).to.equal(calcPercentage(totalSupply.toString(), uADPriceAfterSwap.sub(oneETH).toString()));

    // secondAccount must approve uAR to manage all of its uAR
    // indeed debtCouponMgr will burn the user's uAR
    await expect(uAR.connect(secondAccount).approve(debtCouponMgr.address, secondAccUARBalAfter))
      .to.emit(uAR, "Approval")
      .withArgs(secondAccountAdr, debtCouponMgr.address, secondAccUARBalAfter);

    await expect(debtCouponMgr.connect(secondAccount).burnAutoRedeemTokensForDollars(secondAccUARBalAfter))
      .to.emit(uAR, "Burning")
      .withArgs(secondAccountAdr, secondAccUARBalAfter)
      .and.to.emit(uAD, "Transfer") //  minting of uad;
      .withArgs(ethers.constants.AddressZero, debtCouponMgr.address, mintableUAD)
      .and.to.emit(uAD, "Transfer") //  transfer of uAD to user
      .withArgs(debtCouponMgr.address, secondAccountAdr, secondAccUARBalAfter)
      .and.to.emit(uAD, "Transfer") //  transfer excess minted uAD to excess distributor
      .withArgs(debtCouponMgr.address, excessDollarsDistributor.address, excessUAD)
      .and.to.emit(uAD, "Transfer") //  transfer of 50% of excess minted uAD to treasury
      .withArgs(excessDollarsDistributor.address, await treasury.getAddress(), excessUAD.div(2).toString())
      .and.to.emit(uAR, "Transfer") // burn uAR
      .withArgs(secondAccountAdr, ethers.constants.AddressZero, secondAccUARBalAfter);

    // we minted more uAD than what we needed for our coupon
    expect(mintableUAD).to.be.gt(secondAccUARBalAfter);

    const userUADBalanceAfterRedeem = await uAD.balanceOf(secondAccountAdr);
    expect(userUADBalanceAfterRedeem).to.equal(userUADBalanceBeforeRedeem.add(secondAccUARBalAfter));
    // check that we don't have debt coupon anymore
    const debtCouponsAfterRedeem = await debtCoupon.balanceOf(secondAccountAdr, expiryBlock);
    expect(debtCouponsAfterRedeem).to.equal(0);

    // debtCouponMgr uad balance should be empty because all minted UAD have been transferred
    // to coupon holder and excessDistributor
    debtUADBalance = await uAD.balanceOf(debtCouponMgr.address);
    expect(debtUADBalance).to.equal(0);

    // excess distributor have distributed everything
    const excessDistributoUADBalance = await uAD.balanceOf(excessDollarsDistributor.address);

    // small change remain
    expect(excessDistributoUADBalance).to.equal(0);
  });
  it("should redeem uAR before uDebt if there is not enough minted uAD", async () => {
    const pool0bal = await metaPool.balances(0);
    const pool1bal = await metaPool.balances(1);
    expect(pool0bal).to.equal(ethers.utils.parseEther("10000"));
    expect(pool1bal).to.equal(ethers.utils.parseEther("10000"));

    // remove liquidity one coin 3CRV only so that uAD will be worth less
    const admBalance = await metaPool.balanceOf(await admin.getAddress());
    // calculation to withdraw 1e18 LP token
    // Calculate the amount received when withdrawing and unwrapping in a single coin.
    // Useful for setting _max_burn_amount when calling remove_liquidity_one_coin.
    const lpTo3CRV = await metaPool["calc_withdraw_one_coin(uint256,int128)"](oneETH, 1);

    const expected = lpTo3CRV.div(100).mul(99);
    // approve metapool to burn LP on behalf of admin
    await metaPool.approve(metaPool.address, admBalance);

    // Withdraw a single asset from the pool.
    await metaPool["remove_liquidity_one_coin(uint256,int128,uint256)"](oneETH, 1, expected);

    await twapOracle.update();
    // Price must be below 1 to mint coupons
    const uADPrice = await twapOracle.consult(uAD.address);
    expect(uADPrice).to.be.lt(oneETH);
    // check that total debt is null
    const totalDebt = await debtCoupon.getTotalOutstandingDebt();
    expect(totalDebt).to.equal(0);
    // launch it once to initialize the debt cycle so that getUARReturnedForDollars
    // can give us accurate result
    const secondAccountAdr = await secondAccount.getAddress();
    await expect(debtCouponMgr.connect(secondAccount).exchangeDollarsForUAR(1))
      .to.emit(uAR, "Transfer")
      .withArgs(ethers.constants.AddressZero, secondAccountAdr, 1);

    const amountToExchangeForCoupon = oneETH;
    const amountToExchangeForUAR = oneETH.add(ethers.utils.parseEther("9000"));

    const balanceBefore = await uAD.balanceOf(secondAccountAdr);

    // approve debtCouponManager to burn user's token
    await uAD.connect(secondAccount).approve(debtCouponMgr.address, amountToExchangeForCoupon.add(amountToExchangeForUAR));
    const lastBlock = await ethers.provider.getBlock(await ethers.provider.getBlockNumber());

    const blockHeightDebt = await debtCouponMgr.blockHeightDebt();
    const calculatedUARToMint = calcUARforDollar(
      amountToExchangeForUAR.toString(),
      blockHeightDebt.toString(),
      (lastBlock.number + 1).toString(),
      ethers.utils.parseEther("1").toString()
    );

    const expiryBlock = lastBlock.number + 1 + couponLengthBlocks;
    const secondAccUARBalBefore = await uAR.balanceOf(secondAccountAdr);
    // we exchange uAD for UAR
    await expect(debtCouponMgr.connect(secondAccount).exchangeDollarsForUAR(amountToExchangeForUAR)).to.emit(uAR, "Transfer");
    const uDebtToMint = await couponsForDollarsCalculator.getCouponAmount(amountToExchangeForCoupon);
    // we also exchange the same amount of uAD for uDEBT
    await expect(debtCouponMgr.connect(secondAccount).exchangeDollarsForDebtCoupons(amountToExchangeForCoupon))
      .to.emit(debtCoupon, "MintedCoupons")
      .withArgs(secondAccountAdr, expiryBlock + 1, uDebtToMint);

    const balanceAfter = await uAD.balanceOf(secondAccountAdr);

    expect(balanceBefore.sub(balanceAfter).sub(amountToExchangeForCoupon).sub(amountToExchangeForUAR)).to.equal(0);
    // check that we have uAR with correct premium
    const secondAccUARBalAfter = await uAR.balanceOf(secondAccountAdr);

    expect(secondAccUARBalAfter.sub(secondAccUARBalBefore).sub(calculatedUARToMint).toNumber()).to.be.lessThan(2000000);

    // check that we have a debt coupon with correct premium
    const uDebtCoupons = await debtCoupon.balanceOf(secondAccountAdr, expiryBlock + 1);
    expect(uDebtCoupons).to.equal(uDebtToMint);

    // check outstanding debt now

    const uarTotalSupply = await uAR.totalSupply();
    expect(uarTotalSupply).to.equal(secondAccUARBalAfter);
    await debtCoupon.updateTotalDebt();
    const totalOutstandingDebt = BigNumber.from(await ethers.provider.getStorageAt(debtCoupon.address, 6));

    expect(totalOutstandingDebt).to.equal(uDebtCoupons);

    // Price must be above 1 to redeem coupon
    // we previously removed 3CRV from the pool meaning uAD is <1$ because
    // we have more uAD than 3CRV. In order to make uAD >1$ we will swap 3CRV
    // for uAD.
    // Note that we previously burnt uAD but as we get the price from curve the
    // uAD burnt didn't affect the price
    const whale3CRVBalanceBeforeSwap = await crvToken.balanceOf(curveWhaleAddress);
    const CRVAmountToSwap = ethers.utils.parseEther("1000");

    // Exchange (swap)
    let dy3CRVtouAD = await swap3CRVtoUAD(metaPool, crvToken, CRVAmountToSwap.sub(BigNumber.from(1)), curveWhale);

    await twapOracle.update();
    await swap3CRVtoUAD(metaPool, crvToken, BigNumber.from(1), curveWhale);
    dy3CRVtouAD = dy3CRVtouAD.add(BigNumber.from(1));
    await twapOracle.update();
    const whale3CRVBalance = await crvToken.balanceOf(curveWhaleAddress);
    const whaleuADBalance = await uAD.balanceOf(curveWhaleAddress);

    expect(whaleuADBalance).to.equal(dy3CRVtouAD);
    expect(whale3CRVBalance).to.equal(whale3CRVBalanceBeforeSwap.sub(CRVAmountToSwap));

    await twapOracle.update();
    const uADPriceAfterSwap = await twapOracle.consult(uAD.address);
    expect(uADPriceAfterSwap).to.be.gt(oneETH);

    // now we can redeem the coupon
    // debtCouponMgr uad balance should be empty
    const debtUADBalance = await uAD.balanceOf(debtCouponMgr.address);
    expect(debtUADBalance).to.equal(0);
    const UADBalanceBeforeRedeem = await uAD.balanceOf(secondAccountAdr);
    const mintableUAD = await dollarMintingCalculator.getDollarsToMint();

    // we haven't minted enough UAD to redeem all the uAR
    expect(mintableUAD).to.be.lt(uarTotalSupply);
    // trying to redeem uDEBT should fail

    // secondAccount must approve debtCouponMgr to manage all of its debtCoupons
    // indeed debtCouponMgr will burn the user's debtCoupon
    await expect(debtCoupon.connect(secondAccount).setApprovalForAll(debtCouponMgr.address, true))
      .to.emit(debtCoupon, "ApprovalForAll")
      .withArgs(secondAccountAdr, debtCouponMgr.address, true);

    await expect(debtCouponMgr.connect(secondAccount).redeemCoupons(expiryBlock + 1, uDebtToMint)).to.be.revertedWith(
      "There aren't enough uAD to redeem currently"
    );

    // now we will try to redemm uAR
    const totalSupply = await uAD.totalSupply();
    expect(mintableUAD).to.equal(calcPercentage(totalSupply.toString(), uADPriceAfterSwap.sub(oneETH).toString()));

    // secondAccount must approve uAR to manage all of its uAR
    // indeed debtCouponMgr will burn the user's uAR
    await expect(uAR.connect(secondAccount).approve(debtCouponMgr.address, secondAccUARBalAfter))
      .to.emit(uAR, "Approval")
      .withArgs(secondAccountAdr, debtCouponMgr.address, secondAccUARBalAfter);
    //  we can't redeem all the uAR
    await expect(debtCouponMgr.connect(secondAccount).burnAutoRedeemTokensForDollars(secondAccUARBalAfter))
      .to.emit(uAR, "Burning")
      .withArgs(secondAccountAdr, mintableUAD)
      .and.to.emit(uAD, "Transfer") //  minting of uad;
      .withArgs(ethers.constants.AddressZero, debtCouponMgr.address, mintableUAD)
      .and.to.emit(uAD, "Transfer") //  transfer of uAD to user
      .withArgs(debtCouponMgr.address, secondAccountAdr, mintableUAD);
    const uARBalAfterRedeem = await uAR.balanceOf(secondAccountAdr);
    const uADBalAfterRedeem = await uAD.balanceOf(secondAccountAdr);
    expect(uARBalAfterRedeem).to.equal(secondAccUARBalAfter.sub(mintableUAD));
    expect(uADBalAfterRedeem).to.equal(UADBalanceBeforeRedeem.add(mintableUAD));
  });
  it("exchangeDollarsForUAR and exchange exchangeDollarsForDebtCoupons should work together", async () => {
    const pool0bal = await metaPool.balances(0);
    const pool1bal = await metaPool.balances(1);
    expect(pool0bal).to.equal(ethers.utils.parseEther("10000"));
    expect(pool1bal).to.equal(ethers.utils.parseEther("10000"));

    // remove liquidity one coin 3CRV only so that uAD will be worth less
    const admBalance = await metaPool.balanceOf(await admin.getAddress());
    // calculation to withdraw 1e18 LP token
    // Calculate the amount received when withdrawing and unwrapping in a single coin.
    // Useful for setting _max_burn_amount when calling remove_liquidity_one_coin.
    const lpTo3CRV = await metaPool["calc_withdraw_one_coin(uint256,int128)"](oneETH, 1);

    const expected = lpTo3CRV.div(100).mul(99);
    // approve metapool to burn LP on behalf of admin
    await metaPool.approve(metaPool.address, admBalance);

    // Withdraw a single asset from the pool.
    await metaPool["remove_liquidity_one_coin(uint256,int128,uint256)"](oneETH, 1, expected);

    await twapOracle.update();
    // Price must be below 1 to mint coupons
    const uADPrice = await twapOracle.consult(uAD.address);
    expect(uADPrice).to.be.lt(oneETH);
    // check that total debt is null
    const totalDebt = await debtCoupon.getTotalOutstandingDebt();
    expect(totalDebt).to.equal(0);
    // launch it once to initialize the debt cycle so that getUARReturnedForDollars
    // can give us accurate result
    const secondAccountAdr = await secondAccount.getAddress();
    await expect(debtCouponMgr.connect(secondAccount).exchangeDollarsForUAR(1))
      .to.emit(uAR, "Transfer")
      .withArgs(ethers.constants.AddressZero, secondAccountAdr, 1);

    const amountToExchangeForCoupon = oneETH;
    const amountToExchangeForUAR = oneETH.add(ethers.utils.parseEther("5"));

    const balanceBefore = await uAD.balanceOf(secondAccountAdr);

    // approve debtCouponManager to burn user's token
    await uAD.connect(secondAccount).approve(debtCouponMgr.address, amountToExchangeForCoupon.add(amountToExchangeForUAR));
    const lastBlock = await ethers.provider.getBlock(await ethers.provider.getBlockNumber());

    const blockHeightDebt = await debtCouponMgr.blockHeightDebt();
    const calculatedUARToMint = calcUARforDollar(
      amountToExchangeForUAR.toString(),
      blockHeightDebt.toString(),
      (lastBlock.number + 1).toString(),
      ethers.utils.parseEther("1").toString()
    );

    const expiryBlock = lastBlock.number + 1 + couponLengthBlocks;
    const secondAccUARBalBefore = await uAR.balanceOf(secondAccountAdr);
    // we exchange uAD for UAR
    await expect(debtCouponMgr.connect(secondAccount).exchangeDollarsForUAR(amountToExchangeForUAR)).to.emit(uAR, "Transfer");
    const uDebtToMint = await couponsForDollarsCalculator.getCouponAmount(amountToExchangeForCoupon);
    // we also exchange the same amount of uAD for uDEBT

    await expect(debtCouponMgr.connect(secondAccount).exchangeDollarsForDebtCoupons(amountToExchangeForCoupon))
      .to.emit(debtCoupon, "MintedCoupons")
      .withArgs(secondAccountAdr, expiryBlock + 1, uDebtToMint);

    const balanceAfter = await uAD.balanceOf(secondAccountAdr);

    expect(balanceBefore.sub(balanceAfter).sub(amountToExchangeForCoupon).sub(amountToExchangeForUAR)).to.equal(0);
    // check that we have uAR with correct premium
    const secondAccUARBalAfter = await uAR.balanceOf(secondAccountAdr);

    expect(secondAccUARBalAfter.sub(secondAccUARBalBefore).sub(calculatedUARToMint).toNumber()).to.be.lessThan(2000000);

    // check that we have a debt coupon with correct premium
    const uDebtCoupons = await debtCoupon.balanceOf(secondAccountAdr, expiryBlock + 1);
    expect(uDebtCoupons).to.equal(uDebtToMint);

    // check outstanding debt now
    const uarTotalSupply = await uAR.totalSupply();
    expect(uarTotalSupply).to.equal(secondAccUARBalAfter);
    await debtCoupon.updateTotalDebt();
    const totalOutstandingDebt = BigNumber.from(await ethers.provider.getStorageAt(debtCoupon.address, 6));
    expect(totalOutstandingDebt).to.equal(uDebtCoupons);

    // Price must be above 1 to redeem coupon
    // we previously removed 3CRV from the pool meaning uAD is <1$ because
    // we have more uAD than 3CRV. In order to make uAD >1$ we will swap 3CRV
    // for uAD.
    // Note that we previously burnt uAD but as we get the price from curve the
    // uAD burnt didn't affect the price
    const whale3CRVBalanceBeforeSwap = await crvToken.balanceOf(curveWhaleAddress);
    const CRVAmountToSwap = ethers.utils.parseEther("3000");

    // Exchange (swap)
    let dy3CRVtouAD = await swap3CRVtoUAD(metaPool, crvToken, CRVAmountToSwap.sub(BigNumber.from(1)), curveWhale);

    await twapOracle.update();
    const dy3CRVtouADSecond = await swap3CRVtoUAD(metaPool, crvToken, BigNumber.from(1), curveWhale);
    dy3CRVtouAD = dy3CRVtouAD.add(dy3CRVtouADSecond);
    await twapOracle.update();
    const whale3CRVBalance = await crvToken.balanceOf(curveWhaleAddress);
    const whaleuADBalance = await uAD.balanceOf(curveWhaleAddress);

    expect(whaleuADBalance).to.equal(dy3CRVtouAD);
    expect(whale3CRVBalance).to.equal(whale3CRVBalanceBeforeSwap.sub(CRVAmountToSwap));

    await twapOracle.update();
    const uADPriceAfterSwap = await twapOracle.consult(uAD.address);
    expect(uADPriceAfterSwap).to.be.gt(oneETH);

    // now we can redeem the coupon
    // debtCouponMgr uad balance should be empty
    let debtUADBalance = await uAD.balanceOf(debtCouponMgr.address);
    expect(debtUADBalance).to.equal(0);
    const userUADBalanceBeforeRedeem = await uAD.balanceOf(secondAccountAdr);
    const mintableUAD = await dollarMintingCalculator.getDollarsToMint();

    const excessUAD = mintableUAD.sub(uarTotalSupply).sub(uDebtCoupons);
    const totalSupply = await uAD.totalSupply();

    expect(mintableUAD).to.equal(calcPercentage(totalSupply.toString(), uADPriceAfterSwap.sub(oneETH).toString()));

    // secondAccount must approve uAR to manage all of its uAR
    // indeed debtCouponMgr will burn the user's uAR
    await expect(uAR.connect(secondAccount).approve(debtCouponMgr.address, secondAccUARBalAfter))
      .to.emit(uAR, "Approval")
      .withArgs(secondAccountAdr, debtCouponMgr.address, secondAccUARBalAfter);

    await expect(debtCouponMgr.connect(secondAccount).burnAutoRedeemTokensForDollars(secondAccUARBalAfter))
      .to.emit(uAR, "Burning")
      .withArgs(secondAccountAdr, secondAccUARBalAfter)
      .and.to.emit(uAD, "Transfer") //  minting of uad;
      .withArgs(ethers.constants.AddressZero, debtCouponMgr.address, mintableUAD)
      .and.to.emit(uAD, "Transfer") //  transfer of uAD to user
      .withArgs(debtCouponMgr.address, secondAccountAdr, secondAccUARBalAfter)
      .and.to.emit(uAD, "Transfer") //  transfer excess minted uAD to excess distributor
      .withArgs(debtCouponMgr.address, excessDollarsDistributor.address, excessUAD)
      .and.to.emit(uAD, "Transfer") //  transfer of 50% of excess minted uAD to treasury
      .withArgs(excessDollarsDistributor.address, await treasury.getAddress(), excessUAD.div(2).toString())
      .and.to.emit(uAR, "Transfer") // burn uAR
      .withArgs(secondAccountAdr, ethers.constants.AddressZero, secondAccUARBalAfter);
    const excessDistributionBalanceAfterUARRedeem = await uAD.balanceOf(excessDollarsDistributor.address);
    // we minted more uAD than what we needed for our coupon
    expect(mintableUAD).to.be.gt(secondAccUARBalAfter);

    const userUADBalanceAfterRedeem = await uAD.balanceOf(secondAccountAdr);
    expect(userUADBalanceAfterRedeem).to.equal(userUADBalanceBeforeRedeem.add(secondAccUARBalAfter));
    // check that we still have debt coupons
    const debtCouponsAfterUARRedeem = await debtCoupon.balanceOf(secondAccountAdr, expiryBlock + 1);
    expect(debtCouponsAfterUARRedeem).to.equal(uDebtToMint);
    // check that we still have dollar minted to repay uDebt
    const balanceDebtMgrAfterUARRedeem = await uAD.balanceOf(debtCouponMgr.address);
    expect(balanceDebtMgrAfterUARRedeem).to.equal(uDebtToMint);

    // debtCouponMgr uad balance should not be zero because there are still minted UAD
    // for uDEBT holders
    debtUADBalance = await uAD.balanceOf(debtCouponMgr.address);
    expect(debtUADBalance).to.equal(amountToExchangeForCoupon);
    // exchange the uDebt for uAD
    // secondAccount must approve debtCouponMgr to manage all of its debtCoupons
    // indeed debtCouponMgr will burn the user's debtCoupon
    await expect(debtCoupon.connect(secondAccount).setApprovalForAll(debtCouponMgr.address, true))
      .to.emit(debtCoupon, "ApprovalForAll")
      .withArgs(secondAccountAdr, debtCouponMgr.address, true);
    // the redeem will trigger again some uAD minting as the total supply of uAD is greater
    // after the uAR redeem
    const newMintableUAD = await dollarMintingCalculator.getDollarsToMint();
    //  const newExcessUAD = mintableUAD.sub(uDebtToMint);
    const newTotalSupply = await uAD.totalSupply();
    expect(newMintableUAD).to.equal(calcPercentage(newTotalSupply.toString(), uADPriceAfterSwap.sub(oneETH).toString()));

    // the new calculation is greater than the previous because total supply is greater
    expect(newMintableUAD).to.be.gt(mintableUAD);

    const balanceBeforeDebtRedeem = await uAD.balanceOf(secondAccountAdr);
    await expect(debtCouponMgr.connect(secondAccount).redeemCoupons(expiryBlock + 1, uDebtToMint))
      .to.emit(debtCoupon, "BurnedCoupons")
      .withArgs(secondAccountAdr, expiryBlock + 1, uDebtToMint)
      .and.to.emit(uAD, "Transfer") //  minting of uad is substracted to what was already minted
      .withArgs(
        ethers.constants.AddressZero,
        debtCouponMgr.address,
        newMintableUAD.sub(mintableUAD) // only the difference has been minted
      )
      .and.to.emit(uAD, "Transfer") //  transfer of uAD to user
      .withArgs(debtCouponMgr.address, secondAccountAdr, uDebtToMint)
      .and.to.emit(uAD, "Transfer") //  transfer  excess minted uAD to excess distributor
      .withArgs(debtCouponMgr.address, excessDollarsDistributor.address, newMintableUAD.sub(mintableUAD))
      .and.to.emit(debtCoupon, "TransferSingle") // ERC1155 burn
      .withArgs(debtCouponMgr.address, secondAccountAdr, ethers.constants.AddressZero, expiryBlock + 1, uDebtToMint);

    const debtCouponsAfterDebtRedeem = await debtCoupon.balanceOf(secondAccountAdr, expiryBlock + 1);
    // the debt coupon has been burned
    expect(debtCouponsAfterDebtRedeem).to.equal(0);
    // right amount of uAD has been transfered
    const balanceAfterDebtRedeem = await uAD.balanceOf(secondAccountAdr);
    expect(balanceAfterDebtRedeem).to.equal(balanceBeforeDebtRedeem.add(uDebtToMint));
    // excess distributor has increased is uAD balance
    // with the newly minted uAD
    const excessDistributionBalanceAfterDebtRedeem = await uAD.balanceOf(excessDollarsDistributor.address);
    expect(excessDistributionBalanceAfterDebtRedeem.sub(excessDistributionBalanceAfterUARRedeem)).to.equal(newMintableUAD.sub(mintableUAD));

    // there shouldn't be any uAD left in the DebtManager
    // as all debts have been redeemed
    const balanceDebtMgrAfterDebtRedeem = await uAD.balanceOf(debtCouponMgr.address);
    expect(balanceDebtMgrAfterDebtRedeem).to.equal(0);
  });
  it("burnExpiredCouponsForUGOV should revert if balance is not insufficient", async () => {
    const pool0bal = await metaPool.balances(0);
    const pool1bal = await metaPool.balances(1);
    expect(pool0bal).to.equal(ethers.utils.parseEther("10000"));
    expect(pool1bal).to.equal(ethers.utils.parseEther("10000"));

    // Price must be below 1 to mint coupons
    // remove liquidity one coin 3CRV only so that uAD will be worth less
    const admBalance = await metaPool.balanceOf(await admin.getAddress());

    // calculation to withdraw 1e18 LP token
    // Calculate the amount received when withdrawing and unwrapping in a single coin.
    // Useful for setting _max_burn_amount when calling remove_liquidity_one_coin.
    const lpTo3CRV = await metaPool["calc_withdraw_one_coin(uint256,int128)"](oneETH, 1);

    const expected = lpTo3CRV.div(100).mul(99);
    // approve metapool to burn LP on behalf of admin
    await metaPool.approve(metaPool.address, admBalance);

    // Withdraw a single asset from the pool.
    await metaPool["remove_liquidity_one_coin(uint256,int128,uint256)"](oneETH, 1, expected);
    await twapOracle.update();

    // check that total debt is null
    const totalDebt = await debtCoupon.getTotalOutstandingDebt();
    expect(totalDebt).to.equal(0);
    const amountToExchangeForCoupon = oneETH;
    const secondAccountAdr = await secondAccount.getAddress();
    const balanceBefore = await uAD.balanceOf(secondAccountAdr);

    const lastBlock = await ethers.provider.getBlock(await ethers.provider.getBlockNumber());
    const couponToMint = await couponsForDollarsCalculator.getCouponAmount(amountToExchangeForCoupon);
    const expiryBlock = lastBlock.number + 1 + couponLengthBlocks;

    await expect(debtCouponMgr.connect(secondAccount).exchangeDollarsForDebtCoupons(amountToExchangeForCoupon))
      .to.emit(debtCoupon, "MintedCoupons")
      .withArgs(secondAccountAdr, expiryBlock, couponToMint);

    const balanceAfter = await uAD.balanceOf(secondAccountAdr);

    expect(balanceBefore.sub(balanceAfter).sub(amountToExchangeForCoupon)).to.equal(0);

    // check that we have a debt coupon with correct premium
    const debtCoupons = await debtCoupon.balanceOf(secondAccountAdr, expiryBlock);
    expect(debtCoupons).to.equal(couponToMint);
    await mineNBlock(couponLengthBlocks);
    // increase time so that our coupon are expired
    await expect(debtCouponMgr.connect(secondAccount).burnExpiredCouponsForUGOV(expiryBlock, debtCoupons.add(oneETH))).to.revertedWith(
      "User not enough coupons"
    );
  });
  it("burnExpiredCouponsForUGOV should revert if coupon is not expired", async () => {
    const pool0bal = await metaPool.balances(0);
    const pool1bal = await metaPool.balances(1);
    expect(pool0bal).to.equal(ethers.utils.parseEther("10000"));
    expect(pool1bal).to.equal(ethers.utils.parseEther("10000"));

    // Price must be below 1 to mint coupons
    // remove liquidity one coin 3CRV only so that uAD will be worth less
    const admBalance = await metaPool.balanceOf(await admin.getAddress());

    // calculation to withdraw 1e18 LP token
    // Calculate the amount received when withdrawing and unwrapping in a single coin.
    // Useful for setting _max_burn_amount when calling remove_liquidity_one_coin.
    const lpTo3CRV = await metaPool["calc_withdraw_one_coin(uint256,int128)"](oneETH, 1);

    const expected = lpTo3CRV.div(100).mul(99);
    // approve metapool to burn LP on behalf of admin
    await metaPool.approve(metaPool.address, admBalance);

    // Withdraw a single asset from the pool.
    await metaPool["remove_liquidity_one_coin(uint256,int128,uint256)"](oneETH, 1, expected);
    await twapOracle.update();

    // check that total debt is null
    const totalDebt = await debtCoupon.getTotalOutstandingDebt();
    expect(totalDebt).to.equal(0);
    const amountToExchangeForCoupon = oneETH;
    const secondAccountAdr = await secondAccount.getAddress();
    const balanceBefore = await uAD.balanceOf(secondAccountAdr);

    const lastBlock = await ethers.provider.getBlock(await ethers.provider.getBlockNumber());
    const couponToMint = await couponsForDollarsCalculator.getCouponAmount(amountToExchangeForCoupon);
    const expiryBlock = lastBlock.number + 1 + couponLengthBlocks;

    await expect(debtCouponMgr.connect(secondAccount).exchangeDollarsForDebtCoupons(amountToExchangeForCoupon))
      .to.emit(debtCoupon, "MintedCoupons")
      .withArgs(secondAccountAdr, expiryBlock, couponToMint);

    const balanceAfter = await uAD.balanceOf(secondAccountAdr);

    expect(balanceBefore.sub(balanceAfter).sub(amountToExchangeForCoupon)).to.equal(0);

    // check that we have a debt coupon with correct premium
    const debtCoupons = await debtCoupon.balanceOf(secondAccountAdr, expiryBlock);
    expect(debtCoupons).to.equal(couponToMint);

    // increase time so that our coupon are expired
    await expect(debtCouponMgr.connect(secondAccount).burnExpiredCouponsForUGOV(expiryBlock, debtCoupons.sub(oneETH))).to.revertedWith(
      "Coupon has not expired"
    );
  });
  it("burnExpiredCouponsForUGOV should work if coupon is expired", async () => {
    const pool0bal = await metaPool.balances(0);
    const pool1bal = await metaPool.balances(1);
    expect(pool0bal).to.equal(ethers.utils.parseEther("10000"));
    expect(pool1bal).to.equal(ethers.utils.parseEther("10000"));

    // Price must be below 1 to mint coupons
    // remove liquidity one coin 3CRV only so that uAD will be worth less
    const admBalance = await metaPool.balanceOf(await admin.getAddress());

    // calculation to withdraw 1e18 LP token
    // Calculate the amount received when withdrawing and unwrapping in a single coin.
    // Useful for setting _max_burn_amount when calling remove_liquidity_one_coin.
    const lpTo3CRV = await metaPool["calc_withdraw_one_coin(uint256,int128)"](oneETH, 1);

    const expected = lpTo3CRV.div(100).mul(99);
    // approve metapool to burn LP on behalf of admin
    await metaPool.approve(metaPool.address, admBalance);

    // Withdraw a single asset from the pool.
    await metaPool["remove_liquidity_one_coin(uint256,int128,uint256)"](oneETH, 1, expected);
    await twapOracle.update();

    // check that total debt is null
    const totalDebt = await debtCoupon.getTotalOutstandingDebt();
    expect(totalDebt).to.equal(0);
    const amountToExchangeForCoupon = oneETH;
    const secondAccountAdr = await secondAccount.getAddress();
    const balanceBefore = await uAD.balanceOf(secondAccountAdr);

    const lastBlock = await ethers.provider.getBlock(await ethers.provider.getBlockNumber());
    const couponToMint = await couponsForDollarsCalculator.getCouponAmount(amountToExchangeForCoupon);
    const expiryBlock = lastBlock.number + 1 + couponLengthBlocks;

    await expect(debtCouponMgr.connect(secondAccount).exchangeDollarsForDebtCoupons(amountToExchangeForCoupon))
      .to.emit(debtCoupon, "MintedCoupons")
      .withArgs(secondAccountAdr, expiryBlock, couponToMint);

    const balanceAfter = await uAD.balanceOf(secondAccountAdr);

    expect(balanceBefore.sub(balanceAfter).sub(amountToExchangeForCoupon)).to.equal(0);

    // check that we have a debt coupon with correct premium
    const debtCoupons = await debtCoupon.balanceOf(secondAccountAdr, expiryBlock);
    expect(debtCoupons).to.equal(couponToMint);
    const approve = await debtCoupon.isApprovedForAll(secondAccountAdr, debtCouponMgr.address);
    expect(approve).to.be.false;
    // check outstanding debt now
    const totalOutstandingDebt = await debtCoupon.getTotalOutstandingDebt();
    expect(totalOutstandingDebt).to.equal(debtCoupons);
    const balanceUGOVBefore = await uGOV.balanceOf(secondAccountAdr);
    // increase time so that our coupon are expired
    await ethers.provider.getBlock(await ethers.provider.getBlockNumber());
    await mineNBlock(couponLengthBlocks);
    await ethers.provider.getBlock(await ethers.provider.getBlockNumber());
    const expiredCouponConvertionRate = await debtCouponMgr.expiredCouponConvertionRate();

    const hl = await debtCoupon.holderTokens(secondAccountAdr);
    expect(hl.length).to.equal(1);
    expect(hl[0]).to.equal(expiryBlock);

    // DebtCouponManager should be approved to move user's debtCoupon
    await debtCoupon.connect(secondAccount).setApprovalForAll(debtCouponMgr.address, true);
    const approveAfter = await debtCoupon.isApprovedForAll(secondAccountAdr, debtCouponMgr.address);
    expect(approveAfter).to.be.true;
    await expect(debtCouponMgr.connect(secondAccount).burnExpiredCouponsForUGOV(expiryBlock, debtCoupons.sub(ethers.utils.parseEther("0.5"))))
      .to.emit(debtCoupon, "BurnedCoupons")
      .withArgs(secondAccountAdr, expiryBlock, debtCoupons.sub(ethers.utils.parseEther("0.5")))
      .and.to.emit(uGOV, "Minting")
      .withArgs(secondAccountAdr, debtCouponMgr.address, debtCoupons.sub(ethers.utils.parseEther("0.5")).div(expiredCouponConvertionRate))
      .and.to.emit(uGOV, "Transfer")
      .withArgs(ethers.constants.AddressZero, secondAccountAdr, debtCoupons.sub(ethers.utils.parseEther("0.5")).div(expiredCouponConvertionRate));
    const balanceUGOVAfter = await uGOV.balanceOf(secondAccountAdr);
    expect(balanceUGOVAfter.sub(balanceUGOVBefore)).to.equal(debtCoupons.sub(ethers.utils.parseEther("0.5")).div(expiredCouponConvertionRate));
    // Even if price is above 1 we should be able to redeem coupon

    const CRVAmountToSwap = ethers.utils.parseEther("1000");

    // Exchange (swap)
    let dy3CRVtouAD = await swap3CRVtoUAD(metaPool, crvToken, CRVAmountToSwap.sub(BigNumber.from(1)), curveWhale);
    await twapOracle.update();
    await swap3CRVtoUAD(metaPool, crvToken, BigNumber.from(1), curveWhale);
    dy3CRVtouAD = dy3CRVtouAD.add(BigNumber.from(1));
    await twapOracle.update();

    const whaleuADBalance = await uAD.balanceOf(curveWhaleAddress);
    expect(whaleuADBalance).to.equal(dy3CRVtouAD);

    await twapOracle.update();
    const uADPriceAfterSwap = await twapOracle.consult(uAD.address);

    expect(uADPriceAfterSwap).to.be.gt(oneETH);

    // should work if not enough coupon

    await expect(debtCouponMgr.connect(secondAccount).burnExpiredCouponsForUGOV(expiryBlock, ethers.utils.parseEther("0.5")))
      .to.emit(debtCoupon, "BurnedCoupons")
      .withArgs(secondAccountAdr, expiryBlock, ethers.utils.parseEther("0.5"))
      .and.to.emit(uGOV, "Minting")
      .withArgs(secondAccountAdr, debtCouponMgr.address, ethers.utils.parseEther("0.5").div(expiredCouponConvertionRate))
      .and.to.emit(uGOV, "Transfer")
      .withArgs(ethers.constants.AddressZero, secondAccountAdr, ethers.utils.parseEther("0.5").div(expiredCouponConvertionRate));
    const balanceUGOVAfter2ndRedeem = await uGOV.balanceOf(secondAccountAdr);
    expect(balanceUGOVAfter2ndRedeem.sub(balanceUGOVAfter)).to.equal(ethers.utils.parseEther("0.5").div(expiredCouponConvertionRate));
  });
  it("setExpiredCouponConvertionRate should work", async () => {
    const expiredCouponConvertionRate = await debtCouponMgr.expiredCouponConvertionRate();
    expect(expiredCouponConvertionRate).to.equal(2);
    await expect(debtCouponMgr.setExpiredCouponConvertionRate(42)).to.emit(debtCouponMgr, "ExpiredCouponConvertionRateChanged").withArgs(42, 2);

    const expiredCouponConvertionRateAfter = await debtCouponMgr.expiredCouponConvertionRate();
    expect(expiredCouponConvertionRateAfter).to.equal(42);
  });
  it("setExpiredCouponConvertionRate should fail if not coupon manager", async () => {
    await expect(debtCouponMgr.connect(secondAccount).setExpiredCouponConvertionRate(42)).to.revertedWith("Caller is not a coupon manager");
  });
  it("setCoupon should work", async () => {
    const currentCouponLengthBlocks = await debtCouponMgr.couponLengthBlocks();
    expect(currentCouponLengthBlocks).to.equal(couponLengthBlocks);
    await expect(debtCouponMgr.setCouponLength(42)).to.emit(debtCouponMgr, "CouponLengthChanged").withArgs(42, couponLengthBlocks);

    const couponLengthBlocksAfter = await debtCouponMgr.couponLengthBlocks();
    expect(couponLengthBlocksAfter).to.equal(42);
  });
  it("exchangeDollarsForDebtCoupons should fail if uAD price is >= 1", async () => {
    await expect(debtCouponMgr.connect(secondAccount).exchangeDollarsForDebtCoupons(1)).to.revertedWith("Price must be below 1 to mint coupons");
  });
  it("exchangeDollarsForDebtCoupons should fail if coupon is expired or amount is insufficient", async () => {
    const pool0bal = await metaPool.balances(0);
    const pool1bal = await metaPool.balances(1);
    expect(pool0bal).to.equal(ethers.utils.parseEther("10000"));
    expect(pool1bal).to.equal(ethers.utils.parseEther("10000"));

    // Price must be below 1 to mint coupons
    // remove liquidity one coin 3CRV only so that uAD will be worth less
    const admBalance = await metaPool.balanceOf(await admin.getAddress());

    // calculation to withdraw 1e18 LP token
    // Calculate the amount received when withdrawing and unwrapping in a single coin.
    // Useful for setting _max_burn_amount when calling remove_liquidity_one_coin.
    const lpTo3CRV = await metaPool["calc_withdraw_one_coin(uint256,int128)"](oneETH, 1);

    const expected = lpTo3CRV.div(100).mul(99);
    // approve metapool to burn LP on behalf of admin
    await metaPool.approve(metaPool.address, admBalance);

    // Withdraw a single asset from the pool.
    await metaPool["remove_liquidity_one_coin(uint256,int128,uint256)"](oneETH, 1, expected);

    await twapOracle.update();

    // check that total debt is null
    const totalDebt = await debtCoupon.getTotalOutstandingDebt();
    expect(totalDebt).to.equal(0);
    const amountToExchangeForCoupon = oneETH;
    const secondAccountAdr = await secondAccount.getAddress();
    const balanceBefore = await uAD.balanceOf(secondAccountAdr);

    const lastBlock = await ethers.provider.getBlock(await ethers.provider.getBlockNumber());
    const couponToMint = await couponsForDollarsCalculator.getCouponAmount(amountToExchangeForCoupon);
    const expiryBlock = lastBlock.number + 1 + couponLengthBlocks;

    await expect(debtCouponMgr.connect(secondAccount).exchangeDollarsForDebtCoupons(amountToExchangeForCoupon))
      .to.emit(debtCoupon, "MintedCoupons")
      .withArgs(secondAccountAdr, expiryBlock, couponToMint);

    const balanceAfter = await uAD.balanceOf(secondAccountAdr);

    expect(balanceBefore.sub(balanceAfter).sub(amountToExchangeForCoupon)).to.equal(0);
    // check that we have a debt coupon with correct premium
    const debtCoupons = await debtCoupon.balanceOf(secondAccountAdr, expiryBlock);
    expect(debtCoupons).to.equal(couponToMint);

    // check outstanding debt now
    const totalOutstandingDebt = await debtCoupon.getTotalOutstandingDebt();
    expect(totalOutstandingDebt).to.equal(debtCoupons);

    // Price must be above 1 to redeem coupon
    // we previously removed 3CRV from the pool meaning uAD is <1$ because
    // we have more uAD than 3CRV. In order to make uAD >1$ we will swap 3CRV
    // for uAD.
    // Note that we previously burnt uAD but as we get the price from curve the
    // uAD burnt didn't affect the price
    const whale3CRVBalanceBeforeSwap = await crvToken.balanceOf(curveWhaleAddress);
    const CRVAmountToSwap = ethers.utils.parseEther("1000");

    // Exchange (swap)
    let dy3CRVtouAD = await swap3CRVtoUAD(metaPool, crvToken, CRVAmountToSwap.sub(BigNumber.from(1)), curveWhale);
    await twapOracle.update();
    await swap3CRVtoUAD(metaPool, crvToken, BigNumber.from(1), curveWhale);
    dy3CRVtouAD = dy3CRVtouAD.add(BigNumber.from(1));
    await twapOracle.update();

    const whale3CRVBalance = await crvToken.balanceOf(curveWhaleAddress);
    const whaleuADBalance = await uAD.balanceOf(curveWhaleAddress);

    expect(whaleuADBalance).to.equal(dy3CRVtouAD);
    expect(whale3CRVBalance).to.equal(whale3CRVBalanceBeforeSwap.sub(CRVAmountToSwap));

    await twapOracle.update();
    const uADPriceAfterSwap = await twapOracle.consult(uAD.address);

    expect(uADPriceAfterSwap).to.be.gt(oneETH);

    // should fail if not enough coupon
    await expect(debtCouponMgr.connect(secondAccount).redeemCoupons(expiryBlock, debtCoupons.mul(2))).to.revertedWith("User not enough coupons");
    // should expire after couponLengthBlocks block
    const blockBefore = await ethers.provider.getBlock(await ethers.provider.getBlockNumber());
    await mineNBlock(couponLengthBlocks);
    const blockAfter = await ethers.provider.getBlock(await ethers.provider.getBlockNumber());
    expect(blockAfter.number).to.equal(blockBefore.number + couponLengthBlocks);
    await expect(debtCouponMgr.connect(secondAccount).redeemCoupons(expiryBlock, debtCoupons)).to.revertedWith("Coupon has expired");
  });
  it("exchangeDollarsForDebtCoupons should work", async () => {
    const pool0bal = await metaPool.balances(0);
    const pool1bal = await metaPool.balances(1);
    expect(pool0bal).to.equal(ethers.utils.parseEther("10000"));
    expect(pool1bal).to.equal(ethers.utils.parseEther("10000"));

    // remove liquidity one coin 3CRV only so that uAD will be worth less
    const admBalance = await metaPool.balanceOf(await admin.getAddress());
    // calculation to withdraw 1e18 LP token
    // Calculate the amount received when withdrawing and unwrapping in a single coin.
    // Useful for setting _max_burn_amount when calling remove_liquidity_one_coin.
    const lpTo3CRV = await metaPool["calc_withdraw_one_coin(uint256,int128)"](oneETH, 1);

    const expected = lpTo3CRV.div(100).mul(99);
    // approve metapool to burn LP on behalf of admin
    await metaPool.approve(metaPool.address, admBalance);

    // Withdraw a single asset from the pool.
    await metaPool["remove_liquidity_one_coin(uint256,int128,uint256)"](oneETH, 1, expected);

    await twapOracle.update();
    // Price must be below 1 to mint coupons
    const uADPrice = await twapOracle.consult(uAD.address);
    expect(uADPrice).to.be.lt(oneETH);
    // check that total debt is null
    const totalDebt = await debtCoupon.getTotalOutstandingDebt();
    expect(totalDebt).to.equal(0);
    const amountToExchangeForCoupon = oneETH;
    const secondAccountAdr = await secondAccount.getAddress();
    const balanceBefore = await uAD.balanceOf(secondAccountAdr);

    // approve debtCouponManager to burn user's token
    await uAD.connect(secondAccount).approve(debtCouponMgr.address, amountToExchangeForCoupon);
    const lastBlock = await ethers.provider.getBlock(await ethers.provider.getBlockNumber());
    const couponToMint = await couponsForDollarsCalculator.getCouponAmount(amountToExchangeForCoupon);
    const expiryBlock = lastBlock.number + 1 + couponLengthBlocks;
    await expect(debtCouponMgr.connect(secondAccount).exchangeDollarsForDebtCoupons(amountToExchangeForCoupon))
      .to.emit(debtCoupon, "MintedCoupons")
      .withArgs(secondAccountAdr, expiryBlock, couponToMint);

    const debtIds = await debtCoupon.holderTokens(secondAccountAdr);
    const debtBalanceOfs = debtIds.map((id) => {
      return debtCoupon.balanceOf(secondAccountAdr, id);
    });
    const debtBalances = await Promise.all(debtBalanceOfs);
    let fullBalance = BigNumber.from(0);
    if (debtBalances.length > 0) {
      fullBalance = debtBalances.reduce((prev, cur) => {
        return prev.add(cur);
      });
    }
    expect(fullBalance).to.equal(couponToMint);
    expect(debtIds.length).to.equal(1);
    expect(debtIds[0]).to.equal(expiryBlock);
    const balanceAfter = await uAD.balanceOf(secondAccountAdr);

    expect(balanceBefore.sub(balanceAfter).sub(amountToExchangeForCoupon)).to.equal(0);
    // check that we have a debt coupon with correct premium
    const debtCoupons = await debtCoupon.balanceOf(secondAccountAdr, expiryBlock);
    expect(debtCoupons).to.equal(couponToMint);

    // check outstanding debt now
    const totalOutstandingDebt = await debtCoupon.getTotalOutstandingDebt();
    expect(totalOutstandingDebt).to.equal(debtCoupons);

    // Price must be above 1 to redeem coupon
    // we previously removed 3CRV from the pool meaning uAD is <1$ because
    // we have more uAD than 3CRV. In order to make uAD >1$ we will swap 3CRV
    // for uAD.
    // Note that we previously burnt uAD but as we get the price from curve the
    // uAD burnt didn't affect the price
    const whale3CRVBalanceBeforeSwap = await crvToken.balanceOf(curveWhaleAddress);
    const CRVAmountToSwap = ethers.utils.parseEther("3000");

    // Exchange (swap)
    let dy3CRVtouAD = await swap3CRVtoUAD(metaPool, crvToken, CRVAmountToSwap.sub(BigNumber.from(1)), curveWhale);
    await twapOracle.update();
    const dy3CRVtoUADsecond = await swap3CRVtoUAD(metaPool, crvToken, BigNumber.from(1), curveWhale);
    dy3CRVtouAD = dy3CRVtouAD.add(dy3CRVtoUADsecond);
    await twapOracle.update();
    const whale3CRVBalance = await crvToken.balanceOf(curveWhaleAddress);
    const whaleuADBalance = await uAD.balanceOf(curveWhaleAddress);

    expect(whaleuADBalance).to.equal(dy3CRVtouAD);
    expect(whale3CRVBalance).to.equal(whale3CRVBalanceBeforeSwap.sub(CRVAmountToSwap));

    await twapOracle.update();
    const uADPriceAfterSwap = await twapOracle.consult(uAD.address);
    expect(uADPriceAfterSwap).to.be.gt(oneETH);

    // now we can redeem the coupon
    // 1. this will update the total debt by going through all the debt coupon that are
    // not expired it should be equal to debtCoupons here as we don't have uAR
    // 2. it calculates the mintable uAD based on the mint rules
    // where we don't expand the supply of uAD too much during an up cyle
    // (down cycle begins when we burn uAD for debtCoupon see func: exchangeDollarsForDebtCoupons() )
    // we only expand (price-1)* total Supply % more uAD at maximum see func: getDollarsToMint()
    // this means that you may have coupon left after calling redeemCoupons()
    // this is indeed on a first come first served basis
    // 3. if the minted amount is > totalOutstandingDebt the excess is distributed
    // 10% to treasury 10% to uGov fund and 80% to LP provider

    // debtCouponMgr uad balance should be empty
    let debtUADBalance = await uAD.balanceOf(debtCouponMgr.address);
    expect(debtUADBalance).to.equal(0);
    const userUADBalanceBeforeRedeem = await uAD.balanceOf(secondAccountAdr);
    const mintableUAD = await dollarMintingCalculator.getDollarsToMint();
    const excessUAD = mintableUAD.sub(debtCoupons);
    const totalSupply = await uAD.totalSupply();

    expect(mintableUAD).to.equal(calcPercentage(totalSupply.toString(), uADPriceAfterSwap.sub(oneETH).toString()));

    // secondAccount must approve debtCouponMgr to manage all of its debtCoupons
    // indeed debtCouponMgr will burn the user's debtCoupon
    await expect(debtCoupon.connect(secondAccount).setApprovalForAll(debtCouponMgr.address, true))
      .to.emit(debtCoupon, "ApprovalForAll")
      .withArgs(secondAccountAdr, debtCouponMgr.address, true);

    await expect(debtCouponMgr.connect(secondAccount).redeemCoupons(expiryBlock, debtCoupons))
      .to.emit(debtCoupon, "BurnedCoupons")
      .withArgs(secondAccountAdr, expiryBlock, debtCoupons)
      .and.to.emit(uAD, "Transfer") //  minting of uad;
      .withArgs(ethers.constants.AddressZero, debtCouponMgr.address, mintableUAD)
      .and.to.emit(uAD, "Transfer") //  transfer of uAD to user
      .withArgs(debtCouponMgr.address, secondAccountAdr, debtCoupons)
      .and.to.emit(uAD, "Transfer") //  transfer  excess minted uAD to excess distributor
      .withArgs(debtCouponMgr.address, excessDollarsDistributor.address, excessUAD)
      .and.to.emit(uAD, "Transfer") //  transfer of 50% of excess minted uAD to treasury
      .withArgs(excessDollarsDistributor.address, await treasury.getAddress(), excessUAD.div(2).toString())
      .and.to.emit(debtCoupon, "TransferSingle") // ERC1155
      .withArgs(debtCouponMgr.address, secondAccountAdr, ethers.constants.AddressZero, expiryBlock, debtCoupons);

    const debtAfterIds = await debtCoupon.holderTokens(secondAccountAdr);
    expect(debtAfterIds.length).to.equal(1);
    const debtBalanceAfter = await debtCoupon.balanceOf(secondAccountAdr, debtAfterIds[0]);
    expect(debtBalanceAfter).to.equal(0);
    // we minted more uAD than what we needed for our coupon
    expect(mintableUAD).to.be.gt(debtCoupons);

    const userUADBalanceAfterRedeem = await uAD.balanceOf(secondAccountAdr);
    expect(userUADBalanceAfterRedeem).to.equal(userUADBalanceBeforeRedeem.add(debtCoupons));
    // check that we don't have debt coupon anymore
    const debtCouponsAfterRedeem = await debtCoupon.balanceOf(secondAccountAdr, expiryBlock);
    expect(debtCouponsAfterRedeem).to.equal(0);

    // debtCouponMgr uad balance should be empty because all minted UAD have been transferred
    // to coupon holder and excessDistributor
    debtUADBalance = await uAD.balanceOf(debtCouponMgr.address);
    expect(debtUADBalance).to.equal(0);

    // excess distributor have distributed everything
    const excessDistributoUADBalance = await uAD.balanceOf(excessDollarsDistributor.address);
    // small change remain
    expect(excessDistributoUADBalance).to.equal(BigNumber.from(1));
  });
  it("calling exchangeDollarsForDebtCoupons twice in up cycle should mint uAD a second time only based on the inflation", async () => {
    // Price must be below 1 to mint coupons
    const uADPrice = await twapOracle.consult(uAD.address);
    // remove liquidity one coin 3CRV only so that uAD will be worth less
    const admBalance = await metaPool.balanceOf(await admin.getAddress());

    // calculation to withdraw 1e18 LP token
    // Calculate the amount received when withdrawing and unwrapping in a single coin.
    // Useful for setting _max_burn_amount when calling remove_liquidity_one_coin.
    const lpTo3CRV = await metaPool["calc_withdraw_one_coin(uint256,int128)"](oneETH, 1);

    const expected = lpTo3CRV.div(100).mul(99);
    // approve metapool to burn LP on behalf of admin
    await metaPool.approve(metaPool.address, admBalance);
    await metaPool["remove_liquidity_one_coin(uint256,int128,uint256)"](oneETH, 1, expected);

    await twapOracle.update();
    const uADPriceAfter = await twapOracle.consult(uAD.address);
    expect(uADPriceAfter).to.be.lt(uADPrice);
    // check that total debt is null
    const totalDebt = await debtCoupon.getTotalOutstandingDebt();
    expect(totalDebt).to.equal(0);

    const amountToExchangeForCoupon = ethers.utils.parseEther("2");
    const secondAccountAdr = await secondAccount.getAddress();
    // approve debtCouponManager to burn user's token
    await uAD.connect(secondAccount).approve(debtCouponMgr.address, amountToExchangeForCoupon);
    const lastBlock = await ethers.provider.getBlock(await ethers.provider.getBlockNumber());

    const expiryBlock = lastBlock.number + 1 + couponLengthBlocks;

    await expect(debtCouponMgr.connect(secondAccount).exchangeDollarsForDebtCoupons(amountToExchangeForCoupon)).to.emit(debtCoupon, "MintedCoupons");
    const debtCoupons = await debtCoupon.balanceOf(secondAccountAdr, expiryBlock);
    // Price must be above 1 to redeem coupon
    // we previously removed 3CRV from the pool meaning uAD is <1$ because
    // we have more uAD than 3CRV. In order to make uAD >1$ we will swap 3CRV
    // for uAD.
    // Note that we previously burnt uAD but as we get the price from curve the
    // uAD burnt didn't affect the price

    const CRVAmountToSwap = ethers.utils.parseEther("10000");

    // Exchange (swap)
    await swap3CRVtoUAD(metaPool, crvToken, CRVAmountToSwap.sub(BigNumber.from(1)), curveWhale);
    await twapOracle.update();
    await swap3CRVtoUAD(metaPool, crvToken, BigNumber.from(1), curveWhale);
    await twapOracle.update();

    const uADPriceAfterSwap = await twapOracle.consult(uAD.address);
    expect(uADPriceAfterSwap).to.be.gt(oneETH);

    // now we can redeem the coupon
    // 1. this will update the total debt by going through all the debt coupon that are
    // not expired it should be equal to debtCoupons here as we don't have uAR
    // 2. it calculates the mintable uAD based on the mint rules
    // where we don't expand the supply of uAD too much during an up cyle
    // (down cycle begins when we burn uAD for debtCoupon see func: exchangeDollarsForDebtCoupons() )
    // we only expand (price-1)* total Supply % more uAD at maximum see func: getDollarsToMint()
    // this means that you may have coupon left after calling redeemCoupons()
    // this is indeed on a first come first served basis
    // 3. if the minted amount is > totalOutstandingDebt the excess is distributed
    // 10% to treasury 10% to uGov fund and 80% to LP provider

    // debtCouponMgr uad balance should be empty
    let debtUADBalance = await uAD.balanceOf(debtCouponMgr.address);
    expect(debtUADBalance).to.equal(0);
    const userUADBalanceBeforeRedeem = await uAD.balanceOf(secondAccountAdr);
    const mintableUAD = await dollarMintingCalculator.getDollarsToMint();
    const excessUAD = mintableUAD.sub(debtCoupons);
    const totalSupply = await uAD.totalSupply();
    expect(mintableUAD).to.equal(calcPercentage(totalSupply.toString(), uADPriceAfterSwap.sub(oneETH).toString()));

    // secondAccount must approve debtCouponMgr to manage all of its debtCoupons
    // indeed debtCouponMgr will burn the user's debtCoupon
    await expect(debtCoupon.connect(secondAccount).setApprovalForAll(debtCouponMgr.address, true))
      .to.emit(debtCoupon, "ApprovalForAll")
      .withArgs(secondAccountAdr, debtCouponMgr.address, true);
    // only redeem 1 coupon
    await expect(debtCouponMgr.connect(secondAccount).redeemCoupons(expiryBlock, oneETH))
      .to.emit(debtCoupon, "BurnedCoupons")
      .withArgs(secondAccountAdr, expiryBlock, oneETH)
      .and.to.emit(uAD, "Transfer") //  minting of uad;
      .withArgs(ethers.constants.AddressZero, debtCouponMgr.address, mintableUAD)
      .and.to.emit(uAD, "Transfer") //  transfer of uAD to user
      .withArgs(debtCouponMgr.address, secondAccountAdr, oneETH)
      .and.to.emit(uAD, "Transfer") //  transfer  excess minted uAD to excess distributor
      .withArgs(debtCouponMgr.address, excessDollarsDistributor.address, excessUAD)
      .and.to.emit(uAD, "Transfer") //  transfer of 50% of excess minted uAD to treasury
      .withArgs(excessDollarsDistributor.address, await treasury.getAddress(), excessUAD.div(2).toString())
      .and.to.emit(debtCoupon, "TransferSingle") // ERC1155
      .withArgs(debtCouponMgr.address, secondAccountAdr, ethers.constants.AddressZero, expiryBlock, oneETH);
    // we minted more uAD than what we needed for our coupon
    expect(mintableUAD).to.be.gt(debtCoupons);

    const userUADBalanceAfterRedeem = await uAD.balanceOf(secondAccountAdr);

    expect(userUADBalanceAfterRedeem).to.equal(userUADBalanceBeforeRedeem.add(oneETH));
    // check that we  have still one debt coupon
    const debtCouponsAfterRedeem = await debtCoupon.balanceOf(secondAccountAdr, expiryBlock);
    expect(debtCouponsAfterRedeem).to.equal(oneETH);

    // debtCouponMgr uad balance should not be empty because not all minted UAD have been transfered
    // to coupon holder and excessDistributor
    debtUADBalance = await uAD.balanceOf(debtCouponMgr.address);
    expect(debtUADBalance).to.equal(oneETH);

    // excess distributor have distributed everything in excess
    const excessDistributoUADBalance = await uAD.balanceOf(excessDollarsDistributor.address);
    // no UAD should be left
    expect(excessDistributoUADBalance).to.equal(1);
    //  make sure that calling getDollarsToMint twice doesn't mint all dollars twice
    const mintableUADThisTime = await dollarMintingCalculator.getDollarsToMint();
    const dollarsToMint = mintableUADThisTime.sub(mintableUAD);
    // dollars to mint should be only a fraction of the previously inflation of uAD total Supply
    const beforeSecondRedeemTotalSupply = await uAD.totalSupply();

    const newCalculatedMintedUAD = calcPercentage(beforeSecondRedeemTotalSupply.toString(), uADPriceAfterSwap.sub(oneETH).toString());
    const calculatedDollarToMint = newCalculatedMintedUAD.sub(mintableUAD);

    // check that our calculation match the SC calculation
    expect(calculatedDollarToMint).to.equal(dollarsToMint);
    // redeem the last 1 coupon
    await expect(debtCouponMgr.connect(secondAccount).redeemCoupons(expiryBlock, oneETH))
      .to.emit(debtCoupon, "BurnedCoupons")
      .withArgs(secondAccountAdr, expiryBlock, oneETH)
      .and.to.emit(uAD, "Transfer") //  minting of uad;
      .withArgs(ethers.constants.AddressZero, debtCouponMgr.address, dollarsToMint)
      .and.to.emit(uAD, "Transfer") //  transfer of uAD to user
      .withArgs(debtCouponMgr.address, secondAccountAdr, oneETH)
      .and.to.emit(uAD, "Transfer") //  transfer excess minted uAD to excess distributor
      .withArgs(debtCouponMgr.address, excessDollarsDistributor.address, dollarsToMint)
      .and.to.emit(uAD, "Transfer") //  transfer of 50% of excess minted uAD to treasury
      .withArgs(excessDollarsDistributor.address, await treasury.getAddress(), dollarsToMint.div(2).add(1))
      .and.to.emit(debtCoupon, "TransferSingle") // ERC1155
      .withArgs(debtCouponMgr.address, secondAccountAdr, ethers.constants.AddressZero, expiryBlock, oneETH);

    const finalTotalSupply = await uAD.totalSupply();

    // total supply should only be increased by the difference between what has
    // been calculated and what has been already minted
    expect(finalTotalSupply).to.equal(beforeSecondRedeemTotalSupply.add(dollarsToMint));
  });
  it("calling exchangeDollarsForDebtCoupons twice after up and down cycle should reset dollarsMintedThisCycle to zero", async () => {
    // Price must be below 1 to mint coupons
    const uADPrice = await twapOracle.consult(uAD.address);
    // remove liquidity one coin 3CRV only so that uAD will be worth less
    const admBalance = await metaPool.balanceOf(await admin.getAddress());

    // calculation to withdraw 1e18 LP token
    // Calculate the amount received when withdrawing and unwrapping in a single coin.
    // Useful for setting _max_burn_amount when calling remove_liquidity_one_coin.
    const lpTo3CRV = await metaPool["calc_withdraw_one_coin(uint256,int128)"](oneETH, 1);

    const expected = lpTo3CRV.div(100).mul(99);
    // approve metapool to burn LP on behalf of admin
    await metaPool.approve(metaPool.address, admBalance);

    await metaPool["remove_liquidity_one_coin(uint256,int128,uint256)"](oneETH, 1, expected);

    await twapOracle.update();
    const uADPriceAfter = await twapOracle.consult(uAD.address);
    expect(uADPriceAfter).to.be.lt(uADPrice);
    // check that total debt is null
    const totalDebt = await debtCoupon.getTotalOutstandingDebt();
    expect(totalDebt).to.equal(0);

    const amountToExchangeForCoupon = ethers.utils.parseEther("2");
    const secondAccountAdr = await secondAccount.getAddress();
    // approve debtCouponManager to burn user's token
    await uAD.connect(secondAccount).approve(debtCouponMgr.address, amountToExchangeForCoupon.add(oneETH));
    let lastBlock = await ethers.provider.getBlock(await ethers.provider.getBlockNumber());

    const expiryBlock = lastBlock.number + 1 + couponLengthBlocks;

    await expect(debtCouponMgr.connect(secondAccount).exchangeDollarsForDebtCoupons(amountToExchangeForCoupon)).to.emit(debtCoupon, "MintedCoupons");
    let debtCoupons = await debtCoupon.balanceOf(secondAccountAdr, expiryBlock);
    // Price must be above 1 to redeem coupon
    // we previously removed 3CRV from the pool meaning uAD is <1$ because
    // we have more uAD than 3CRV. In order to make uAD >1$ we will swap 3CRV
    // for uAD.
    // Note that we previously burnt uAD but as we get the price from curve the
    // uAD burnt didn't affect the price

    let CRVAmountToSwap = ethers.utils.parseEther("10000");

    // Exchange (swap)
    await swap3CRVtoUAD(metaPool, crvToken, CRVAmountToSwap.sub(BigNumber.from(1)), curveWhale);
    await twapOracle.update();
    await swap3CRVtoUAD(metaPool, crvToken, BigNumber.from(1), curveWhale);
    await twapOracle.update();

    let uADPriceAfterSwap = await twapOracle.consult(uAD.address);
    expect(uADPriceAfterSwap).to.be.gt(oneETH);

    // now we can redeem the coupon
    // 1. this will update the total debt by going through all the debt coupon that are
    // not expired it should be equal to debtCoupons here as we don't have uAR
    // 2. it calculates the mintable uAD based on the mint rules
    // where we don't expand the supply of uAD too much during an up cyle
    // (down cycle begins when we burn uAD for debtCoupon see func: exchangeDollarsForDebtCoupons() )
    // we only expand (price-1)* total Supply % more uAD at maximum see func: getDollarsToMint()
    // this means that you may have coupon left after calling redeemCoupons()
    // this is indeed on a first come first served basis
    // 3. if the minted amount is > totalOutstandingDebt the excess is distributed
    // 10% to treasury 10% to uGov fund and 80% to LP provider

    // debtCouponMgr uad balance should be empty
    let debtUADBalance = await uAD.balanceOf(debtCouponMgr.address);
    expect(debtUADBalance).to.equal(0);
    const userUADBalanceBeforeRedeem = await uAD.balanceOf(secondAccountAdr);
    const mintableUAD = await dollarMintingCalculator.getDollarsToMint();
    const excessUAD = mintableUAD.sub(debtCoupons);
    let totalSupply = await uAD.totalSupply();

    expect(mintableUAD).to.equal(calcPercentage(totalSupply.toString(), uADPriceAfterSwap.sub(oneETH).toString()));

    // secondAccount must approve debtCouponMgr to manage all of its debtCoupons
    // indeed debtCouponMgr will burn the user's debtCoupon
    await expect(debtCoupon.connect(secondAccount).setApprovalForAll(debtCouponMgr.address, true))
      .to.emit(debtCoupon, "ApprovalForAll")
      .withArgs(secondAccountAdr, debtCouponMgr.address, true);
    // only redeem 1 coupon
    await expect(debtCouponMgr.connect(secondAccount).redeemCoupons(expiryBlock, oneETH))
      .to.emit(debtCoupon, "BurnedCoupons")
      .withArgs(secondAccountAdr, expiryBlock, oneETH)
      .and.to.emit(uAD, "Transfer") //  minting of uad;
      .withArgs(ethers.constants.AddressZero, debtCouponMgr.address, mintableUAD)
      .and.to.emit(uAD, "Transfer") //  transfer of uAD to user
      .withArgs(debtCouponMgr.address, secondAccountAdr, oneETH)
      .and.to.emit(uAD, "Transfer") //  transfer  excess minted uAD to excess distributor
      .withArgs(debtCouponMgr.address, excessDollarsDistributor.address, excessUAD)
      .and.to.emit(uAD, "Transfer") //  transfer of 50% of excess minted uAD to treasury
      .withArgs(excessDollarsDistributor.address, await treasury.getAddress(), excessUAD.div(2).toString())
      .and.to.emit(debtCoupon, "TransferSingle") // ERC1155
      .withArgs(debtCouponMgr.address, secondAccountAdr, ethers.constants.AddressZero, expiryBlock, oneETH);
    // we minted more uAD than what we needed for our coupon
    expect(mintableUAD).to.be.gt(debtCoupons);

    const userUADBalanceAfterRedeem = await uAD.balanceOf(secondAccountAdr);

    expect(userUADBalanceAfterRedeem).to.equal(userUADBalanceBeforeRedeem.add(oneETH));
    // check that we  have still one debt coupon less
    debtCoupons = await debtCoupon.balanceOf(secondAccountAdr, expiryBlock);
    expect(debtCoupons).to.equal(amountToExchangeForCoupon.sub(oneETH));

    // debtCouponMgr uad balance should not be empty because not all minted UAD have been transfered
    // to coupon holder and excessDistributor
    debtUADBalance = await uAD.balanceOf(debtCouponMgr.address);
    expect(debtUADBalance).to.equal(oneETH);

    // excess distributor have distributed everything in excess
    const excessDistributoUADBalance = await uAD.balanceOf(excessDollarsDistributor.address);
    // no UAD should be left
    expect(excessDistributoUADBalance).to.equal(1);

    // swap again to go down 1$ and up again
    const uADAmountToSwap = ethers.utils.parseEther("1000");
    await swapUADto3CRV(metaPool, uAD, uADAmountToSwap.sub(BigNumber.from(1)), secondAccount);
    await twapOracle.update();
    await swapUADto3CRV(metaPool, uAD, BigNumber.from(1), secondAccount);
    await twapOracle.update();

    uADPriceAfterSwap = await twapOracle.consult(uAD.address);
    expect(uADPriceAfterSwap).to.be.lt(oneETH);
    // mint debtCoupon this is needed to reset the dollarsMintedThisCycle
    lastBlock = await ethers.provider.getBlock(await ethers.provider.getBlockNumber());
    const newExpiryBlock = lastBlock.number + 1 + couponLengthBlocks;
    totalSupply = await uAD.totalSupply();
    await expect(debtCouponMgr.connect(secondAccount).exchangeDollarsForDebtCoupons(oneETH)).to.emit(debtCoupon, "MintedCoupons");

    const newDebtCoupons = await debtCoupon.balanceOf(secondAccountAdr, newExpiryBlock);
    // coupon premium is 1/(1-total_debt/total_supply)²
    expect(newDebtCoupons).to.equal(calcPremium(oneETH.toString(), totalSupply.toString(), oneETH.toString()));
    // swap to be > 1$
    CRVAmountToSwap = ethers.utils.parseEther("10000");

    // Exchange (swap)
    await swap3CRVtoUAD(metaPool, crvToken, CRVAmountToSwap.sub(BigNumber.from(1)), curveWhale);
    await twapOracle.update();
    await swap3CRVtoUAD(metaPool, crvToken, BigNumber.from(1), curveWhale);
    await twapOracle.update();

    uADPriceAfterSwap = await twapOracle.consult(uAD.address);
    expect(uADPriceAfterSwap).to.be.gt(oneETH);

    //  make sure that calling getDollarsToMint twice doesn't mint all dollars twice
    const mintableUADThisTime = await dollarMintingCalculator.getDollarsToMint();

    // dollars to mint should be only a fraction of the previously inflation of uAD total Supply
    totalSupply = await uAD.totalSupply();
    const newCalculatedMintedUAD = calcPercentage(totalSupply.toString(), uADPriceAfterSwap.sub(oneETH).toString());
    expect(newCalculatedMintedUAD).to.equal(mintableUADThisTime);

    // redeem the last 1 coupon
    await expect(debtCouponMgr.connect(secondAccount).redeemCoupons(expiryBlock, debtCoupons))
      .to.emit(debtCoupon, "BurnedCoupons")
      .withArgs(secondAccountAdr, expiryBlock, debtCoupons)
      .and.to.emit(uAD, "Transfer") //  minting of uad;
      .withArgs(ethers.constants.AddressZero, debtCouponMgr.address, mintableUADThisTime)
      .and.to.emit(uAD, "Transfer") //  transfer of uAD to user
      .withArgs(debtCouponMgr.address, secondAccountAdr, debtCoupons)
      .and.to.emit(uAD, "Transfer") //  transfer  excess minted uAD to excess distributor
      .withArgs(debtCouponMgr.address, excessDollarsDistributor.address, mintableUADThisTime.sub(newDebtCoupons))
      .and.to.emit(uAD, "Transfer") //  transfer of 50% of excess minted uAD to treasury
      .withArgs(excessDollarsDistributor.address, await treasury.getAddress(), mintableUADThisTime.sub(newDebtCoupons).div(2))
      .and.to.emit(debtCoupon, "TransferSingle") // ERC1155
      .withArgs(debtCouponMgr.address, secondAccountAdr, ethers.constants.AddressZero, expiryBlock, debtCoupons);
  });
});
