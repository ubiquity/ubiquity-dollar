import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { ERC20 } from "../artifacts/types/ERC20";
import { UbiquityAlgorithmicDollarManager } from "../artifacts/types/UbiquityAlgorithmicDollarManager";
import { UbiquityAlgorithmicDollar } from "../artifacts/types/UbiquityAlgorithmicDollar";
import { CurveUADIncentive } from "../artifacts/types/CurveUADIncentive";
import { BondingShare } from "../artifacts/types/BondingShare";
import { Bonding } from "../artifacts/types/Bonding";
import { IMetaPool } from "../artifacts/types/IMetaPool";
import { UbiquityAutoRedeem } from "../artifacts/types/UbiquityAutoRedeem";
import { UbiquityGovernance } from "../artifacts/types/UbiquityGovernance";
import { IUniswapV2Router02 } from "../artifacts/types/IUniswapV2Router02";
import { SushiSwapPool } from "../artifacts/types/SushiSwapPool";
import { IUniswapV2Pair } from "../artifacts/types/IUniswapV2Pair";
import pressAnyKey from "../utils/flow";

const func: DeployFunction = async (hre: HardhatRuntimeEnvironment) => {
  const { deployments, getNamedAccounts, ethers, network } = hre;

  // hardhat local

  /* const ubqAdmin = "0xefC0e701A824943b469a694aC564Aa1efF7Ab7dd";
  const admin = ethers.provider.getSigner(ubqAdmin);
  const adminAdr = await admin.getAddress();
  await network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [ubqAdmin],
  }); */

  const [admin] = await ethers.getSigners();
  const adminAdr = admin.address;

  /*   let mgrAdr = "0xf1df21D46921Ca23906c2689b9DA25e63e686934";
  let uADdeployAddress = "0xf967DB57518fd2270b309c256db32596527F8709";
  let uGovdeployAddress = "0x8b2403Ec6470194c789736571E2AA1C91B5B568F";
  let UARForDollarsCalculatorAddress = "";
  let couponsForDollarsCalculatorAddress = "";
  let dollarMintingCalculatorAddress =
    "0x552b513d1aAed6a1CF37eA6bAe3ffCaDBc8D5ca5"; */
  let mgrAdr = "";
  let uADdeployAddress = "";
  let uGovdeployAddress = "";
  let UARForDollarsCalculatorAddress = "";
  let couponsForDollarsCalculatorAddress = "";
  let dollarMintingCalculatorAddress = "";
  const couponLengthBlocks = 1110857;
  let curve3CrvToken = "";
  let curveFactory = "";
  let curve3CrvBasePool = "";
  let curveWhaleAddress = "";
  // let ubq = "ubq.eth";
  ({ curve3CrvToken, curveFactory, curve3CrvBasePool, curveWhaleAddress } = await getNamedAccounts());
  deployments.log(
    `*****
  admin address :`,
    adminAdr,
    `
  `
  );

  const opts = {
    from: adminAdr,
    log: true,
  };
  if (mgrAdr.length === 0) {
    const mgr = await deployments.deploy("UbiquityAlgorithmicDollarManager", {
      args: [adminAdr],
      ...opts,
    });
    mgrAdr = mgr.address;
  }

  const mgrFactory = await ethers.getContractFactory("UbiquityAlgorithmicDollarManager");

  const manager: UbiquityAlgorithmicDollarManager = mgrFactory.attach(
    mgrAdr // mgr.address
  ) as UbiquityAlgorithmicDollarManager;

  deployments.log(`UbiquityAlgorithmicDollarManager deployed at:`, manager.address);
  // uAD
  if (uADdeployAddress.length === 0) {
    const uADdeploy = await deployments.deploy("UbiquityAlgorithmicDollar", {
      args: [manager.address],
      ...opts,
    });

    uADdeployAddress = uADdeploy.address;
  }
  /* */
  const uadFactory = await ethers.getContractFactory("UbiquityAlgorithmicDollar");

  const uAD: UbiquityAlgorithmicDollar = uadFactory.attach(uADdeployAddress) as UbiquityAlgorithmicDollar;

  const dollarTokenAdrFromMgr = await manager.dollarTokenAddress();
  if (dollarTokenAdrFromMgr !== uAD.address) {
    deployments.log("dollarTokenAddress will be set to:", uAD.address);
    await manager.connect(admin).setDollarTokenAddress(uAD.address);
  }

  deployments.log("UbiquityAlgorithmicDollar deployed at:", uAD.address);

  // uGov

  if (uGovdeployAddress.length === 0) {
    const uGov = await deployments.deploy("UbiquityGovernance", {
      args: [manager.address],
      ...opts,
    });

    uGovdeployAddress = uGov.address;
  }
  const uGOVFactory = await ethers.getContractFactory("UbiquityGovernance");
  const uGOV: UbiquityGovernance = uGOVFactory.attach(uGovdeployAddress) as UbiquityGovernance;

  const govTokenAdrFromMgr = await manager.governanceTokenAddress();
  if (govTokenAdrFromMgr !== uGovdeployAddress) {
    deployments.log("UbiquityGovernance will be set to:", uGovdeployAddress);
    await manager.connect(admin).setGovernanceTokenAddress(uGovdeployAddress);
  }

  deployments.log("UbiquityGovernance deployed at:", uGovdeployAddress);
  // set twap Oracle Address

  const crvToken = (await ethers.getContractAt("ERC20", curve3CrvToken)) as ERC20;
  deployments.log("crvToken deployed at:", crvToken.address);

  // set uAR for dollar Calculator

  if (UARForDollarsCalculatorAddress.length === 0) {
    const uARCalc = await deployments.deploy("UARForDollarsCalculator", {
      args: [manager.address],
      ...opts,
    });

    UARForDollarsCalculatorAddress = uARCalc.address;
  }
  const uarCalcAdrFromMgr = await manager.uarCalculatorAddress();
  if (uarCalcAdrFromMgr !== UARForDollarsCalculatorAddress) {
    deployments.log("uarCalculator will be set to:", UARForDollarsCalculatorAddress);
    await manager.connect(admin).setUARCalculatorAddress(UARForDollarsCalculatorAddress);
  }

  deployments.log("uAR for dollar Calculator deployed at:", UARForDollarsCalculatorAddress);

  // set coupon for dollar Calculator
  if (couponsForDollarsCalculatorAddress.length === 0) {
    const couponsForDollarsCalculator = await deployments.deploy("CouponsForDollarsCalculator", {
      args: [manager.address],
      ...opts,
    });

    couponsForDollarsCalculatorAddress = couponsForDollarsCalculator.address;
  }
  const couponCalcAdrFromMgr = await manager.couponCalculatorAddress();
  if (couponCalcAdrFromMgr !== couponsForDollarsCalculatorAddress) {
    deployments.log("coupons For Dollars Calculator will be set to:", couponsForDollarsCalculatorAddress);
    await manager.connect(admin).setCouponCalculatorAddress(couponsForDollarsCalculatorAddress);
  }

  deployments.log("coupons for dollar Calculator deployed at:", couponsForDollarsCalculatorAddress);

  // set Dollar Minting Calculator

  if (dollarMintingCalculatorAddress.length === 0) {
    const dollarMintingCalculator = await deployments.deploy("DollarMintingCalculator", {
      args: [manager.address],
      ...opts,
    });

    dollarMintingCalculatorAddress = dollarMintingCalculator.address;
  }
  const dollarMintingCalcAdrFromMgr = await manager.dollarMintingCalculatorAddress();
  if (dollarMintingCalcAdrFromMgr !== dollarMintingCalculatorAddress) {
    deployments.log("Dollars Minting Calculator will be set to:", dollarMintingCalculatorAddress);
    await manager.connect(admin).setDollarMintingCalculatorAddress(dollarMintingCalculatorAddress);
  }

  deployments.log("dollar minting Calculator deployed at:", dollarMintingCalculatorAddress);

  // set debt coupon token

  const debtCoupon = await deployments.deploy("DebtCoupon", {
    args: [manager.address],
    ...opts,
  });
  await manager.connect(admin).setDebtCouponAddress(debtCoupon.address);
  deployments.log("debt coupon deployed at:", debtCoupon.address);
  const debtCouponMgr = await deployments.deploy("DebtCouponManager", {
    args: [manager.address, couponLengthBlocks],
    ...opts,
  });
  deployments.log("debt coupon manager deployed at:", debtCouponMgr.address);
  // debtCouponMgr should have the COUPON_MANAGER role to mint debtCoupon
  const COUPON_MANAGER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("COUPON_MANAGER"));
  // debtCouponMgr should have the UBQ_MINTER_ROLE to mint uAD for debtCoupon Redeem
  const UBQ_MINTER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("UBQ_MINTER_ROLE"));
  // debtCouponMgr should have the UBQ_BURNER_ROLE to burn uAD when minting debtCoupon
  const UBQ_BURNER_ROLE = ethers.utils.keccak256(ethers.utils.toUtf8Bytes("UBQ_BURNER_ROLE"));

  const isDebtMgrIsCouponMgr = await manager.connect(admin).hasRole(COUPON_MANAGER_ROLE, debtCouponMgr.address);
  if (!isDebtMgrIsCouponMgr) {
    await manager.connect(admin).grantRole(COUPON_MANAGER_ROLE, debtCouponMgr.address);
    deployments.log("debt coupon manager has been granted COUPON_MANAGER_ROLE");
  }

  const isDebtMgrIsMinter = await manager.connect(admin).hasRole(UBQ_MINTER_ROLE, debtCouponMgr.address);
  if (!isDebtMgrIsMinter) {
    await manager.connect(admin).grantRole(UBQ_MINTER_ROLE, debtCouponMgr.address);
    deployments.log("debt coupon manager has been granted UBQ_MINTER_ROLE");
  }
  const isDebtMgrIsBurner = await manager.connect(admin).hasRole(UBQ_BURNER_ROLE, debtCouponMgr.address);
  if (isDebtMgrIsBurner) {
    await manager.connect(admin).grantRole(UBQ_BURNER_ROLE, debtCouponMgr.address);
    deployments.log("debt coupon manager has been granted UBQ_BURNER_ROLE");
  }

  // to calculate the totalOutstanding debt we need to take into account autoRedeemToken.totalSupply

  const uAR = await deployments.deploy("UbiquityAutoRedeem", {
    args: [manager.address],
    ...opts,
  });
  const uARTokenAdrFromMgr = await manager.autoRedeemTokenAddress();
  if (uARTokenAdrFromMgr !== uAR.address) {
    await manager.connect(admin).setuARTokenAddress(uAR.address);
    deployments.log("uARTokenAddress is equal at:", uAR.address);
  }

  const treasuryAdrFromMgr = await manager.treasuryAddress();
  if (treasuryAdrFromMgr !== adminAdr) {
    await manager.connect(admin).setTreasuryAddress(adminAdr);
  }

  deployments.log("treasury is equal to admin was  set at:", adminAdr);

  const uarFactory = await ethers.getContractFactory("UbiquityAutoRedeem");

  const myUAR: UbiquityAutoRedeem = uarFactory.attach(uAR.address) as UbiquityAutoRedeem;

  const balUarAdm = await myUAR.balanceOf(adminAdr);
  if (balUarAdm.lt(ethers.utils.parseEther("250000"))) {
    await myUAR.connect(admin).raiseCapital(ethers.utils.parseEther("250000"));
    const adminUARBal = await myUAR.connect(admin).balanceOf(adminAdr);
    deployments.log(`  *** capital raised for admin:${adminAdr}  at:${ethers.utils.formatEther(adminUARBal)}`);
  }
  deployments.log("ubiquity auto redeem deployed at:", uAR.address);
  // when the debtManager mint uAD it there is too much it distribute the excess to
  const excessDollarsDistributor = await deployments.deploy("ExcessDollarsDistributor", {
    args: [manager.address],
    ...opts,
  });

  const excessDollarsDistribFromMgr = await manager.getExcessDollarsDistributor(debtCouponMgr.address);
  if (excessDollarsDistribFromMgr !== excessDollarsDistributor.address) {
    await manager.connect(admin).setExcessDollarsDistributor(debtCouponMgr.address, excessDollarsDistributor.address);

    deployments.log("excess dollars distributor deployed at:", excessDollarsDistributor.address);
  }

  // set treasury,uGOVFund and lpReward address needed for excessDollarsDistributor

  // DEPLOY BondingShare Contract
  const bondingShareDeploy = await deployments.deploy("BondingShare", {
    args: [manager.address],
    ...opts,
  });
  const bondingShareFactory = await ethers.getContractFactory("BondingShare");
  const bondingShare: BondingShare = bondingShareFactory.attach(bondingShareDeploy.address) as BondingShare;

  const bondingShareAdrFromMgr = await manager.bondingShareAddress();
  if (bondingShareAdrFromMgr !== bondingShare.address) {
    await manager.connect(admin).setBondingShareAddress(bondingShare.address);
    deployments.log("bondingShare deployed at:", bondingShare.address);
  }

  // DEPLOY Ubiquity library
  const ubiquityFormulas = await deployments.deploy("UbiquityFormulas", opts);

  const formulasAdrFromMgr = await manager.formulasAddress();
  if (formulasAdrFromMgr !== ubiquityFormulas.address) {
    await manager.connect(admin).setFormulasAddress(ubiquityFormulas.address);
    deployments.log("ubiquity formulas deployed at:", bondingShare.address);
  }
  // bonding
  const bondingDeploy = await deployments.deploy("Bonding", {
    args: [manager.address, ethers.constants.AddressZero],
    ...opts,
  });
  const bondingFactory = await ethers.getContractFactory("Bonding");
  const bonding: Bonding = bondingFactory.attach(bondingDeploy.address) as Bonding;

  const isBondingMinter = await manager.connect(admin).hasRole(UBQ_MINTER_ROLE, bonding.address);
  if (!isBondingMinter) {
    // bonding should have the UBQ_MINTER_ROLE to mint bonding shares
    await manager.connect(admin).grantRole(UBQ_MINTER_ROLE, bonding.address);
  }

  const isBondingBurner = await manager.connect(admin).hasRole(UBQ_BURNER_ROLE, bonding.address);
  if (isBondingBurner) {
    // bonding should have the UBQ_BURNER_ROLE to burn bonding shares
    await manager.connect(admin).grantRole(UBQ_BURNER_ROLE, bonding.address);
  }

  await bonding.connect(admin).setBlockCountInAWeek(46550);
  const blockCountInAWeek = await bonding.blockCountInAWeek();
  deployments.log("blockCountInAWeek set to:", blockCountInAWeek);

  const bondingCtrFromMgr = await manager.bondingContractAddress();
  if (bondingCtrFromMgr !== bonding.address) {
    await manager.connect(admin).setBondingContractAddress(bonding.address);
    deployments.log("setBondingContractAddress to:", bonding.address);
  }
  // incentive
  const curveIncentiveDeploy = await deployments.deploy("CurveUADIncentive", {
    args: [manager.address],
    ...opts,
  });
  const incentiveFactory = await ethers.getContractFactory("CurveUADIncentive");

  const curveIncentive: CurveUADIncentive = incentiveFactory.attach(curveIncentiveDeploy.address) as CurveUADIncentive;
  deployments.log("curveIncentive deployed at:", curveIncentive.address);

  const isSellPenaltyOn = await curveIncentive.connect(admin).isSellPenaltyOn();

  if (isSellPenaltyOn) {
    // turn off Sell Penalty
    await curveIncentive.connect(admin).switchSellPenalty();
    deployments.log("curveIncentive SELL penalty activate:", await curveIncentive.connect(admin).isSellPenaltyOn());
  }
  const isBuyIncentiveOn = await curveIncentive.connect(admin).isBuyIncentiveOn();
  if (!isBuyIncentiveOn) {
    deployments.log("curveIncentive BUY penalty activate:", await curveIncentive.connect(admin).isBuyIncentiveOn());
  }

  const isIncentiveBurner = await manager.connect(admin).hasRole(UBQ_BURNER_ROLE, curveIncentive.address);
  if (!isIncentiveBurner) {
    // curveIncentive should have the UBQ_BURNER_ROLE to burn uAD during incentive
    await manager.connect(admin).grantRole(UBQ_BURNER_ROLE, curveIncentive.address);
    deployments.log("curveIncentive has been granted UBQ_BURNER_ROLE");
  }

  const isIncentiveMinter = await manager.connect(admin).hasRole(UBQ_MINTER_ROLE, curveIncentive.address);
  if (!isIncentiveMinter) {
    // curveIncentive should have the UBQ_MINTER_ROLE to mint uGOV during incentive
    await manager.connect(admin).grantRole(UBQ_MINTER_ROLE, curveIncentive.address);
    deployments.log("curveIncentive has been granted UBQ_MINTER_ROLE");
  }
  const net = await ethers.provider.getNetwork();
  deployments.log(`Current chain ID: ${net.chainId}`);

  await uAD.connect(admin).mint(manager.address, ethers.utils.parseEther("10"));
  deployments.log(`10 uAD were minted for the manager`);

  const balMgrUAD = await uAD.balanceOf(manager.address);
  deployments.log(`-- manager: ${ethers.utils.formatEther(balMgrUAD)} uAD`);
  /** TO BE REMOVED FOR MAINNET */
  // we should transfer 3CRV manually to the manager contract
  // kindly ask a whale to give us some 3CRV
  if (net.chainId === 31337) {
    // hardhat local
    await network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [curveWhaleAddress],
    });
    const curveWhale = ethers.provider.getSigner(curveWhaleAddress);
    await crvToken.connect(curveWhale).transfer(manager.address, ethers.utils.parseEther("10"));
  }
  deployments.log(`We expect you to transfer 10 3CRV to the manager:${manager.address}`);

  await pressAnyKey();
  const balMgrCRV = await crvToken.balanceOf(manager.address);
  deployments.log(`-- manager: ${ethers.utils.formatEther(balMgrCRV)} 3CRV`);
  deployments.log(`now deploying metapool`);
  let metaPoolAddr = await manager.connect(admin).stableSwapMetaPoolAddress();
  if (metaPoolAddr === ethers.constants.AddressZero) {
    // deploy the stableswap pool we need 3CRV and uAD
    await manager.connect(admin).deployStableSwapPool(curveFactory, curve3CrvBasePool, crvToken.address, 10, 4000000);
    // setup the oracle
    metaPoolAddr = await manager.connect(admin).stableSwapMetaPoolAddress();
    deployments.log("metaPoolAddr deployed at:", metaPoolAddr);
  }

  // Twap
  const twapOracle = await deployments.deploy("TWAPOracle", {
    args: [metaPoolAddr, uAD.address, curve3CrvToken],
    ...opts,
  });
  deployments.log("twapOracle deployed at:", twapOracle.address);

  const twapOracleAdrFromMgr = await manager.twapOracleAddress();
  if (twapOracleAdrFromMgr !== twapOracle.address) {
    await manager.connect(admin).setTwapOracleAddress(twapOracle.address);
  }
  // set the incentive contract to act upon transfer from and to the curve pool
  await manager.connect(admin).setIncentiveToUAD(metaPoolAddr, curveIncentive.address);
  // DEPLOY MasterChef
  const masterChef = await deployments.deploy("MasterChef", {
    args: [manager.address],
    ...opts,
  });

  const masterChefAdrFromMgr = await manager.masterChefAddress();
  if (masterChefAdrFromMgr !== masterChef.address) {
    await manager.connect(admin).setMasterChefAddress(masterChef.address);
    deployments.log("masterChef deployed at:", masterChef.address);
  }

  const isChefMinter = await manager.connect(admin).hasRole(UBQ_MINTER_ROLE, masterChef.address);
  if (!isChefMinter) {
    await manager.connect(admin).grantRole(UBQ_MINTER_ROLE, masterChef.address);
    deployments.log("masterChef has been granted UBQ_MINTER_ROLE");
  }
  // get some token for the faucet to the admin
  await uAD.connect(admin).mint(adminAdr, ethers.utils.parseEther("20000"));
  const metaPool = (await ethers.getContractAt("IMetaPool", metaPoolAddr)) as IMetaPool;

  /* await crvToken
    .connect(curveWhale)
    .transfer(admin.address, ethers.utils.parseEther("20000")); */

  const uADBal = await uAD.balanceOf(adminAdr);
  const crvBal = await crvToken.balanceOf(adminAdr);
  const lpBal = await metaPool.balanceOf(adminAdr);
  deployments.log(`
    ****
    admin addr charged :
    uAD:${ethers.utils.formatEther(uADBal)}
    3crv:${ethers.utils.formatEther(crvBal)}
    uAD-3CRV LP:${ethers.utils.formatEther(lpBal)}
    UbiquityAlgorithmicDollarManager deployed at:${manager.address}
    uAD deployed at:${uAD.address}
    uAD-3CRV metapool deployed at:${metaPoolAddr}
    3crv deployed at:${crvToken.address}
    `);
  deployments.log(`
    ****
    let's deploy the UAD-UGOV SushiPool
    `);
  //  }

  // need some uGOV to provide liquidity
  const routerAdr = "0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F"; // SushiV2Router02

  await uGOV.connect(admin).mint(adminAdr, ethers.utils.parseEther("1000"));

  await uAD.connect(admin).approve(routerAdr, ethers.utils.parseEther("10000"));
  await uGOV.connect(admin).approve(routerAdr, ethers.utils.parseEther("1000"));
  const admUgovBal = ethers.utils.formatEther(await uGOV.balanceOf(adminAdr));
  const admUADBal = ethers.utils.formatEther(await uAD.balanceOf(adminAdr));
  deployments.log(` ****
   admin get
   ${admUgovBal} uGOV and
   ${admUADBal}  uAD
   before deploying the UAD-UGOV SushiPool
    `);
  const router = (await ethers.getContractAt("IUniswapV2Router02", routerAdr)) as IUniswapV2Router02;

  const sushiSwapPoolAddress = await manager.connect(admin).sushiSwapPoolAddress();

  if (sushiSwapPoolAddress === ethers.constants.AddressZero) {
    await router
      .connect(admin)
      .addLiquidity(
        uAD.address,
        uGOV.address,
        ethers.utils.parseEther("10000"),
        ethers.utils.parseEther("1000"),
        ethers.utils.parseEther("9900"),
        ethers.utils.parseEther("990"),
        adminAdr,
        1625414021
      );

    const sushiFactory = await ethers.getContractFactory("SushiSwapPool");
    const sushiUGOVPool = (await sushiFactory.deploy(mgrAdr)) as SushiSwapPool;
    await manager.connect(admin).setSushiSwapPoolAddress(sushiUGOVPool.address);
    deployments.log(`
    ****
    manager setSushiSwapPoolAddress to  ${sushiUGOVPool.address}

    `);

    const pairAdr = await sushiUGOVPool.pair();
    deployments.log(`
    ****
    manager setSushiSwapPoolAddress Pair:${pairAdr}

    `);
    const ugovUadPair = (await ethers.getContractAt("IUniswapV2Pair", pairAdr)) as IUniswapV2Pair;
    const reserves = await ugovUadPair.getReserves();
    const admLPBal = await ugovUadPair.balanceOf(adminAdr);

    deployments.log(`
    ****
    uAD.address,:${uAD.address}
    uGOV.address,:${uGOV.address}
    token0:${await ugovUadPair.token0()}
    token1:${await ugovUadPair.token1()}
    reserves[0]:${ethers.utils.formatEther(reserves[0])}
    reserves[1]:${ethers.utils.formatEther(reserves[1])}
    admin sushi uGOVuAD LP token   ${ethers.utils.formatEther(admLPBal)}
    `);
  }

  const mgrtwapOracleAddress = await manager.twapOracleAddress();
  const mgrdebtCouponAddress = await manager.debtCouponAddress();
  const mgrDollarTokenAddress = await manager.dollarTokenAddress();
  const mgrcouponCalculatorAddress = await manager.couponCalculatorAddress();
  const mgrdollarMintingCalculatorAddress = await manager.dollarMintingCalculatorAddress();
  const mgrbondingShareAddress = await manager.bondingShareAddress();
  const mgrbondingContractAddress = await manager.bondingContractAddress();
  const mgrstableSwapMetaPoolAddress = await manager.stableSwapMetaPoolAddress();
  const mgrcurve3PoolTokenAddress = await manager.curve3PoolTokenAddress(); // 3CRV
  const mgrtreasuryAddress = await manager.treasuryAddress();
  const mgruGOVTokenAddress = await manager.governanceTokenAddress();
  const mgrsushiSwapPoolAddress = await manager.sushiSwapPoolAddress(); // sushi pool uAD-uGOV
  const mgrmasterChefAddress = await manager.masterChefAddress();
  const mgrformulasAddress = await manager.formulasAddress();
  const mgrautoRedeemTokenAddress = await manager.autoRedeemTokenAddress(); // uAR
  const mgruarCalculatorAddress = await manager.uarCalculatorAddress(); // uAR calculator

  const mgrExcessDollarsDistributor = await manager.getExcessDollarsDistributor(debtCouponMgr.address);

  deployments.log(`
    ****
    debtCouponMgr:${debtCouponMgr.address}
    manager ALL VARS:
    mgrtwapOracleAddress:${mgrtwapOracleAddress}
    debtCouponAddress:${mgrdebtCouponAddress}
    uADTokenAddress:${mgrDollarTokenAddress}
    couponCalculatorAddress:${mgrcouponCalculatorAddress}
    dollarMintingCalculatorAddress:${mgrdollarMintingCalculatorAddress}
    bondingShareAddress:${mgrbondingShareAddress}
    bondingContractAddress:${mgrbondingContractAddress}
    stableSwapMetaPoolAddress:${mgrstableSwapMetaPoolAddress}
    curve3PoolTokenAddress:${mgrcurve3PoolTokenAddress}
    treasuryAddress:${mgrtreasuryAddress}
    uGOVTokenAddress:${mgruGOVTokenAddress}
    sushiSwapPoolAddress:${mgrsushiSwapPoolAddress}
    masterChefAddress:${mgrmasterChefAddress}
    formulasAddress:${mgrformulasAddress}
    autoRedeemTokenAddress:${mgrautoRedeemTokenAddress}
    uarCalculatorAddress:${mgruarCalculatorAddress}
    ExcessDollarsDistributor:${mgrExcessDollarsDistributor}
    `);

  deployments.log(`
    ***
    10000 uAD were minted for the treasury aka admin ${adminAdr}
    don't forget to add liquidity to metapool:${metaPoolAddr} with these uAD
    first you need to call approve on uAD:${uAD.address} and crvToken:${crvToken.address}
    then call metaPool["add_liquidity(uint256[2],uint256)"] or go through crv.finance
    ***
    `);

  await uAD.connect(admin).approve(metaPoolAddr, ethers.utils.parseEther("10000"));
  await crvToken.connect(admin).approve(metaPoolAddr, ethers.utils.parseEther("10000"));
  deployments.log(`
      ***
      approve was called for admin:${adminAdr} on uAD:${uAD.address} and crvToken:${crvToken.address}
      for 10k uad and 10k 3crv`);
  deployments.log(`
      We can now add liquidity to metapool:${metaPoolAddr} with these uAD and 3CRV
      either call metaPool["add_liquidity(uint256[2],uint256)"] or go through crv.finance
      here is the actual balance for the admin addr
      uAD:${ethers.utils.formatEther(await uAD.balanceOf(adminAdr))}
      3CRV:${ethers.utils.formatEther(await crvToken.balanceOf(adminAdr))}
      ***
      `);

  await pressAnyKey();
  deployments.log(`
    Providing liquidity to the metapool current LP balance:
      ${ethers.utils.formatEther(await metaPool.balanceOf(adminAdr))}
    `);
  await metaPool.connect(admin)["add_liquidity(uint256[2],uint256)"]([ethers.utils.parseEther("10000"), ethers.utils.parseEther("10000")], 0);
  deployments.log(`
    liquidity Added to the metapool current LP balance:
      ${ethers.utils.formatEther(await metaPool.balanceOf(adminAdr))}
    `);
  deployments.log(`
    That's all folks !
    `);
};
export default func;
func.tags = ["UbiquityAlgorithmicDollarManager"];
