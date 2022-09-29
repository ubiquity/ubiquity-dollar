// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../../src/dollar/BondingV2.sol";
import "../../src/dollar/mocks/MockBondingV1.sol";
import "../../src/dollar/BondingFormulas.sol";
import "../../src/dollar/BondingShareV2.sol";
import "../../src/dollar/interfaces/IMetaPool.sol";
import "../../src/dollar/UbiquityGovernance.sol";
import "../../src/dollar/UbiquityAlgorithmicDollarManager.sol";
import "../../src/dollar/mocks/MockuADToken.sol";
import "../../src/dollar/UbiquityFormulas.sol";
import "../../src/dollar/mocks/MockTWAPOracle.sol";
import "../../src/dollar/MasterChefV2.sol";
import "../../src/dollar/UARForDollarsCalculator.sol";
import "../../src/dollar/interfaces/ICurveFactory.sol";
import "../../src/dollar/interfaces/IMasterChef.sol";
import "../../src/dollar/CouponsForDollarsCalculator.sol";
import "../../src/dollar/DollarMintingCalculator.sol";
import "../../src/dollar/mocks/MockDebtCoupon.sol";
import "../../src/dollar/DebtCouponManager.sol";
import "../../src/dollar/UbiquityAutoRedeem.sol";
import "../../src/dollar/ExcessDollarsDistributor.sol";
import "../../src/dollar/SushiSwapPool.sol";
import "../../src/dollar/interfaces/IERC1155Ubiquity.sol";
import "../../src/dollar/mocks/MockUniRouter02.sol";
import "../../src/dollar/mocks/MockUniFactory.sol";



import "forge-std/Test.sol";


contract EnvironmentSetUp is Test {

    using stdStorage for StdStorage;

    Bonding bondingV1;
    BondingV2 bondingV2;
    BondingFormulas bFormulas;
    BondingShareV2 bondingShareV2;
    UbiquityGovernance uGov;
    UbiquityAlgorithmicDollarManager manager;
    MockuADToken uAD;
    UbiquityFormulas uFormulas;
    MockTWAPOracle twapOracle;
    MasterChefV2 chefV2;
    UARForDollarsCalculator uarCalc;
    CouponsForDollarsCalculator couponCalc;
    DollarMintingCalculator dollarMintCalc;
    MockDebtCoupon debtCoupon;
    DebtCouponManager debtCouponMgr;
    UbiquityAutoRedeem uAR;
    ExcessDollarsDistributor excessDollarsDistributor;
    SushiSwapPool sushiUGOVPool;
    UniswapV2Factory factory;
    UniswapV2Router02 router;

    IERC1155Ubiquity bondingShareV1 = IERC1155Ubiquity(0x0013B6033dd999676Dc547CEeCEA29f781D8Db17);
     
    IMetaPool metapool = IMetaPool(0x20955CB69Ae1515962177D164dfC9522feef567E);
    IMasterChef chefV1 = IMasterChef(0x8fFCf9899738e4633A721904609ffCa0a2C44f3D);

    IERC20 DAI = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F);
    IERC20 USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 crvToken = IERC20(0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490);
    
    ICurveFactory curvePoolFactory = ICurveFactory(0x0959158b6040D32d04c301A72CBFD6b39E21c9AE);

    address admin = address(0x1);
    address treasury = address(0x3);
    address secondAccount = address(0x4);
    address thirdAccount = address(0x5);
    address fourthAccount = address(0x6);
    address fifthAccount = address(0x7);
    address bondingZeroAccount = address(0x8);
    address bondingMinAccount = address(0x9);
    address bondingMaxAccount = address(0x10);

    address sablier = 0xA4fc358455Febe425536fd1878bE67FfDBDEC59a;
    address curve3CrvBasePool = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;
    address curveWhaleAddress = 0xC2872ab688400940d5a6041599b3F7de20730d49;
    address daiWhaleAddress = 0x16463c0fdB6BA9618909F5b120ea1581618C1b9E;
    address usdcWhaleAddress = 0x72A53cDBBcc1b9efa39c834A540550e23463AAcB;
    address curve3CrvToken = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;


    string uri = "https://bafybeifibz4fhk4yag5reupmgh5cdbm2oladke4zfd7ldyw7avgipocpmy.ipfs.infura-ipfs.io/";
    uint256 couponLengthBlocks = 100;

    address[] migrating;
    uint256[] migrateLP;
    uint256[] locked;


    function setUp() public virtual{
        
        vm.startPrank(admin);
        manager = new UbiquityAlgorithmicDollarManager(admin);

        bondingV1 = new Bonding(address(manager), sablier);

        uAD = new MockuADToken(10000e18);
        manager.setDollarTokenAddress(address(uAD));

        debtCoupon = new MockDebtCoupon(100);
        manager.setDebtCouponAddress(address(debtCoupon));

        uFormulas = new UbiquityFormulas();
        manager.setFormulasAddress(address(uFormulas));

        twapOracle = new MockTWAPOracle(address(metapool), address(uAD), address(curve3CrvToken), 100, 100);
        manager.setTwapOracleAddress(address(twapOracle));

        uGov = new UbiquityGovernance(address(manager));
        manager.setGovernanceTokenAddress(address(uGov));
        //manager.grantRole(manager.BONDING_MANAGER_ROLE(), admin);

        bondingV1.setBlockCountInAWeek(420);
        manager.setBondingContractAddress(address(bondingV1));

        bondingShareV1.setApprovalForAll(address(bondingV1), true);
        
        manager.setTreasuryAddress(treasury);

        uGov.mint(thirdAccount, 1000e18);
        uAD.mint(thirdAccount, 10000e18);
        vm.stopPrank();

        vm.startPrank(thirdAccount);
        uAD.approve(address(router), 10000e18);
        uGov.approve(address(router), 1000e18);
        router.addLiquidity(
            address(uAD), 
            address(uGov), 
            10000e18, 
            1000e18, 
            9900e18, 
            990e18,
            thirdAccount,
            block.timestamp + 100);
        vm.stopPrank();

        vm.startPrank(admin);

        sushiUGOVPool = new SushiSwapPool(address(manager));
        manager.setSushiSwapPoolAddress(address(sushiUGOVPool));

        address[5] memory mintings = [
            admin, 
            fourthAccount, 
            bondingZeroAccount, 
            bondingMinAccount, 
            bondingMaxAccount];

        for(uint i = 0; i < mintings.length; ++i) {
            uAD.mint(mintings[i], 10000e18);
        }

        manager.grantRole(manager.UBQ_MINTER_ROLE(), address(bondingV1));
        manager.grantRole(manager.UBQ_BURNER_ROLE(), address(bondingV1));

        uAD.mint(curveWhaleAddress, 10e18);

        vm.stopPrank();

        address[4] memory crvDeal = [address(manager), bondingMaxAccount, bondingMinAccount, fourthAccount];

        for(uint i; i < crvDeal.length; ++i) {
            deal(address(crvToken), crvDeal[i], 10000e18);
        }
        

        vm.startPrank(admin);
        manager.deployStableSwapPool(address(curvePoolFactory), curve3CrvBasePool, curve3CrvToken, 10, 4000000);
        metapool.transfer(address(bondingV1), 100e18);
        metapool.transfer(secondAccount, 1000e18);

        uarCalc = new UARForDollarsCalculator(address(manager));
        manager.setUARCalculatorAddress(address(uarCalc));

        couponCalc = new CouponsForDollarsCalculator(address(manager));
        manager.setCouponCalculatorAddress(address(couponCalc));

        dollarMintCalc = new DollarMintingCalculator(address(manager));
        manager.setDollarMintingCalculatorAddress(address(dollarMintCalc));

        debtCouponMgr = new DebtCouponManager(address(manager), couponLengthBlocks);

        manager.grantRole(manager.COUPON_MANAGER_ROLE(), address(debtCouponMgr));
        manager.grantRole(manager.UBQ_MINTER_ROLE(), address(debtCouponMgr));
        manager.grantRole(manager.UBQ_BURNER_ROLE(), address(debtCouponMgr));

        uAR = new UbiquityAutoRedeem(address(manager));
        manager.setuARTokenAddress(address(uAR));

        excessDollarsDistributor = new ExcessDollarsDistributor(address(manager));
        manager.setExcessDollarsDistributor(address(debtCouponMgr), address(excessDollarsDistributor));

        manager.setMasterChefAddress(address(chefV1));
        manager.grantRole(manager.UBQ_MINTER_ROLE(), address(chefV1));

        vm.stopPrank();

        vm.startPrank(bondingMinAccount);
        uAD.approve(address(metapool), 10000e18);
        crvToken.approve(address(metapool), 10000e18);
        vm.stopPrank();

        vm.startPrank(bondingMaxAccount);
        uAD.approve(address(metapool), 10000e18);
        crvToken.approve(address(metapool), 10000e18);
        vm.stopPrank();

        vm.startPrank(fourthAccount);
        uAD.approve(address(metapool), 10000e18);
        crvToken.approve(address(metapool), 10000e18);
        vm.stopPrank();

        uint256[2] memory amounts_ = [uint256(100e18), uint256(100e18)];

        uint256 dyuAD2LP = metapool.calc_token_amount(amounts_, true);

        vm.prank(bondingMinAccount);
        metapool.add_liquidity(amounts_, dyuAD2LP * 99 / 100);

        vm.prank(bondingMaxAccount);
        metapool.add_liquidity(amounts_, dyuAD2LP * 99 / 100);

        vm.prank(fourthAccount);
        metapool.add_liquidity(amounts_, dyuAD2LP * 99 / 100);

        uint256 bondingMinBal = metapool.balanceOf(bondingMinAccount);
        vm.startPrank(bondingMinAccount);
        metapool.approve(address(bondingV1), bondingMinBal);
        bondingV1.deposit(bondingMinBal, 1);
        vm.stopPrank();

        uint256 bondingMaxBal = metapool.balanceOf(bondingMaxAccount);
        vm.startPrank(bondingMaxAccount);
        metapool.approve(address(bondingV1), bondingMaxBal);
        bondingV1.deposit(bondingMaxBal, 208);
        vm.stopPrank();

        vm.prank(bondingMaxAccount);
        uint256[] memory bondingMaxIds = bondingShareV1.holderTokens();
        uint256 bsMaxAmount = bondingShareV1.balanceOf(bondingMaxAccount, bondingMaxIds[0]);

        vm.prank(bondingMinAccount);
        uint256[] memory bondingMinIds = bondingShareV1.holderTokens();
        uint256 bsMinAmount = bondingShareV1.balanceOf(bondingMinAccount, bondingMinIds[0]);
        
        assertLt(bsMinAmount, bsMaxAmount);

        address[] memory tos;
        uint256[] memory amounts;
        uint256[] memory ids;

        chefV2 = MasterChefV2(address(manager));
        manager.grantRole(manager.UBQ_MINTER_ROLE(), address(chefV2));
        manager.grantRole(manager.UBQ_TOKEN_MANAGER_ROLE(), admin);
        chefV2.setUGOVPerBlock(10e18);

        bondingShareV2 = new BondingShareV2(address(manager), uri);
        manager.setBondingShareAddress(address(bondingShareV2));

        bFormulas = new BondingFormulas();

        migrating = [bondingZeroAccount, bondingMinAccount, bondingMaxAccount];
        migrateLP = [0, bondingMinBal, bondingMaxBal];
        locked = [uint256(1), uint256(1), uint256(208)];

        bondingV2 = new BondingV2(address(manager), address(bFormulas), migrating, migrateLP, locked);

        bondingV1.sendDust(address(bondingV2), address(metapool), bondingMinBal + bondingMaxBal);

        bondingV2.setMigrating(true);

        manager.grantRole(manager.UBQ_MINTER_ROLE(), address(bondingV2));
        bondingV2.setBlockCountInAWeek(420);

        manager.setBondingContractAddress(address(bondingV2));

        manager.revokeRole(manager.UBQ_MINTER_ROLE(), address(chefV1));
        manager.revokeRole(manager.UBQ_MINTER_ROLE(), address(bondingV1));
        manager.revokeRole(manager.UBQ_BURNER_ROLE(), address(bondingV1));
        vm.stopPrank();

        vm.prank(secondAccount);
        bondingShareV1.setApprovalForAll(address(bondingV1), true);

        vm.prank(thirdAccount);
        bondingShareV1.setApprovalForAll(address(bondingV1), true);
    }


}