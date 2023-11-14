// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/console.sol";
import {DiamondTestSetup} from "../DiamondTestSetup.sol";
import {IDollarAmoMinter} from "../../../src/dollar/interfaces/IDollarAmoMinter.sol";
import {LibUbiquityPoolV2} from "../../../src/dollar/libraries/LibUbiquityPoolV2.sol";
import {MockERC20} from "../../../src/dollar/mocks/MockERC20.sol";
import {MockMetaPool} from "../../../src/dollar/mocks/MockMetaPool.sol";

contract MockDollarAmoMinter is IDollarAmoMinter {
    function collateralDollarBalance() external pure returns (uint256) {
        return 0;
    }

    function collateralIndex() external pure returns (uint256) {
        return 0;
    }
}

contract UbiquityPoolFacetV2Test is DiamondTestSetup {
    MockDollarAmoMinter dollarAmoMinter;
    MockERC20 collateralToken;
    MockMetaPool curveDollarMetaPool;
    MockERC20 curveTriPoolLpToken;
    address user = address(1);

    // Events
    event AmoMinterAdded(address amoMinterAddress);
    event AmoMinterRemoved(address amoMinterAddress);
    event CollateralPriceSet(uint256 collateralIndex, uint256 newPrice);
    event CollateralToggled(uint256 collateralIndex, bool newState);
    event FeesSet(
        uint256 collateralIndex,
        uint256 newMintFee,
        uint256 newRedeemFee
    );
    event MRBToggled(uint256 collateralIndex, uint8 toggleIndex);
    event PoolCeilingSet(uint256 collateralIndex, uint256 newCeiling);
    event PriceThresholdsSet(
        uint256 newMintPriceThreshold,
        uint256 newRedeemPriceThreshold
    );
    event RedemptionDelaySet(uint256 redemptionDelay);

    function setUp() public override {
        super.setUp();

        vm.startPrank(admin);

        // init collateral token
        collateralToken = new MockERC20("COLLATERAL", "CLT", 18);

        // init Curve 3CRV-LP token
        curveTriPoolLpToken = new MockERC20("3CRV", "3CRV", 18);

        // init Curve Dollar-3CRV LP metapool
        curveDollarMetaPool = new MockMetaPool(
            address(dollarToken),
            address(curveTriPoolLpToken)
        );

        // add collateral token to the pool
        uint poolCeiling = 50_000e18; // max 50_000 of collateral tokens is allowed
        ubiquityPoolFacetV2.addCollateralToken(
            address(collateralToken),
            poolCeiling
        );
        // enable collateral at index 0
        ubiquityPoolFacetV2.toggleCollateral(0);
        // set mint and redeem fees
        ubiquityPoolFacetV2.setFees(
            0, // collateral index
            10000, // 1% mint fee
            20000 // 2% redeem fee
        );
        // set redemption delay to 2 blocks
        ubiquityPoolFacetV2.setRedemptionDelay(2);
        // set mint price threshold to $1.01 and redeem price to $0.99
        ubiquityPoolFacetV2.setPriceThresholds(1010000, 990000);

        // init AMO minter
        dollarAmoMinter = new MockDollarAmoMinter();
        // add AMO minter
        ubiquityPoolFacetV2.addAmoMinter(address(dollarAmoMinter));

        // stop being admin
        vm.stopPrank();

        // set metapool for TWAP oracle
        vm.prank(owner);
        twapOracleDollar3PoolFacet.setPool(
            address(curveDollarMetaPool),
            address(curveTriPoolLpToken)
        );

        // mint 100 collateral tokens to the user
        collateralToken.mint(address(user), 100e18);
        // user approves the pool to transfer collateral
        vm.prank(user);
        collateralToken.approve(address(ubiquityPoolFacetV2), 100e18);
    }

    //=====================
    // Modifiers
    //=====================

    function testCollateralEnabled_ShouldRevert_IfCollateralIsDisabled()
        public
    {
        // admin disables collateral
        vm.prank(admin);
        ubiquityPoolFacetV2.toggleCollateral(0);

        // user tries to mint Dollars
        vm.prank(user);
        vm.expectRevert("Collateral disabled");
        ubiquityPoolFacetV2.mintDollar(0, 1, 1, 1);
    }

    function testOnlyAmoMinters_ShouldRevert_IfCalledNoByAmoMinter() public {
        vm.prank(user);
        vm.expectRevert("Not an AMO Minter");
        ubiquityPoolFacetV2.amoMinterBorrow(1);
    }

    //=====================
    // Views
    //=====================

    function testAllCollaterals_ShouldReturnAllCollateralTokenAddresses()
        public
    {
        address[] memory collateralAddresses = ubiquityPoolFacetV2
            .allCollaterals();
        assertEq(collateralAddresses.length, 1);
        assertEq(collateralAddresses[0], address(collateralToken));
    }

    function testCollateralInformation_ShouldRevert_IfCollateralIsDisabled()
        public
    {
        // admin disables collateral
        vm.prank(admin);
        ubiquityPoolFacetV2.toggleCollateral(0);

        vm.expectRevert("Invalid collateral");
        ubiquityPoolFacetV2.collateralInformation(address(collateralToken));
    }

    function testCollateralInformation_ShouldReturnCollateralInformation()
        public
    {
        LibUbiquityPoolV2.CollateralInformation
            memory info = ubiquityPoolFacetV2.collateralInformation(
                address(collateralToken)
            );
        assertEq(info.index, 0);
        assertEq(info.symbol, "CLT");
        assertEq(info.collateralAddress, address(collateralToken));
        assertEq(info.isEnabled, true);
        assertEq(info.missingDecimals, 0);
        assertEq(info.price, 1_000_000);
        assertEq(info.poolCeiling, 50_000e18);
        assertEq(info.mintPaused, false);
        assertEq(info.redeemPaused, false);
        assertEq(info.borrowingPaused, false);
        assertEq(info.mintingFee, 10000);
        assertEq(info.redemptionFee, 20000);
    }

    function testCollateralUsdBalance_ShouldReturnTotalAmountOfCollateralInUsd()
        public
    {
        vm.prank(admin);
        ubiquityPoolFacetV2.setPriceThresholds(
            1000000, // mint threshold
            990000 // redeem threshold
        );

        // user sends 100 collateral tokens and gets 99 Dollars
        vm.prank(user);
        ubiquityPoolFacetV2.mintDollar(
            0, // collateral index
            100e18, // Dollar amount
            99e18, // min amount of Dollars to mint
            100e18 // max collateral to send
        );

        uint balanceTally = ubiquityPoolFacetV2.collateralUsdBalance();
        assertEq(balanceTally, 100e18);
    }

    function testFreeCollateralBalance_ShouldReturnCollateralAmountAvailableForBorrowingByAmoMinters()
        public
    {
        vm.prank(admin);
        ubiquityPoolFacetV2.setPriceThresholds(
            1000000, // mint threshold
            1000000 // redeem threshold
        );

        // user sends 100 collateral tokens and gets 99 Dollars (-1% mint fee)
        vm.prank(user);
        ubiquityPoolFacetV2.mintDollar(
            0, // collateral index
            100e18, // Dollar amount
            99e18, // min amount of Dollars to mint
            100e18 // max collateral to send
        );

        // user redeems 99 Dollars for 97.02 (accounts for 2% redemption fee) collateral tokens
        vm.prank(user);
        ubiquityPoolFacetV2.redeemDollar(
            0, // collateral index
            99e18, // Dollar amount
            90e18 // min collateral out
        );

        uint freeCollateralAmount = ubiquityPoolFacetV2.freeCollateralBalance(
            0
        );
        assertEq(freeCollateralAmount, 2.98e18);
    }

    function testGetDollarInCollateral_ShouldReturnAmountOfDollarsWhichShouldBeMintedForInputCollateral()
        public
    {
        uint amount = ubiquityPoolFacetV2.getDollarInCollateral(0, 100e18);
        assertEq(amount, 100e18);
    }

    function testGetDollarPriceUsd_ShouldReturnDollarPriceInUsd() public {
        uint dollarPriceUsd = ubiquityPoolFacetV2.getDollarPriceUsd();
        assertEq(dollarPriceUsd, 1_000_000);
    }

    //====================
    // Public functions
    //====================

    function testMintDollar_ShouldRevert_IfMintingIsPaused() public {
        // admin pauses minting
        vm.prank(admin);
        ubiquityPoolFacetV2.toggleMRB(0, 0);

        vm.prank(user);
        vm.expectRevert("Minting is paused");
        ubiquityPoolFacetV2.mintDollar(
            0, // collateral index
            100e18, // Dollar amount
            90e18, // min amount of Dollars to mint
            100e18 // max collateral to send
        );
    }

    function testMintDollar_ShouldRevert_IfDollarPriceUsdIsTooLow() public {
        vm.prank(user);
        vm.expectRevert("Dollar price too low");
        ubiquityPoolFacetV2.mintDollar(
            0, // collateral index
            100e18, // Dollar amount
            90e18, // min amount of Dollars to mint
            100e18 // max collateral to send
        );
    }

    function testMintDollar_ShouldRevert_OnDollarAmountSlippage() public {
        vm.prank(admin);
        ubiquityPoolFacetV2.setPriceThresholds(
            1000000, // mint threshold
            990000 // redeem threshold
        );

        vm.prank(user);
        vm.expectRevert("Dollar slippage");
        ubiquityPoolFacetV2.mintDollar(
            0, // collateral index
            100e18, // Dollar amount
            100e18, // min amount of Dollars to mint
            100e18 // max collateral to send
        );
    }

    function testMintDollar_ShouldRevert_OnCollateralAmountSlippage() public {
        vm.prank(admin);
        ubiquityPoolFacetV2.setPriceThresholds(
            1000000, // mint threshold
            990000 // redeem threshold
        );

        vm.prank(user);
        vm.expectRevert("Collateral slippage");
        ubiquityPoolFacetV2.mintDollar(
            0, // collateral index
            100e18, // Dollar amount
            90e18, // min amount of Dollars to mint
            10e18 // max collateral to send
        );
    }

    function testMintDollar_ShouldRevert_OnReachingPoolCeiling() public {
        vm.prank(admin);
        ubiquityPoolFacetV2.setPriceThresholds(
            1000000, // mint threshold
            990000 // redeem threshold
        );

        vm.prank(user);
        vm.expectRevert("Pool ceiling");
        ubiquityPoolFacetV2.mintDollar(
            0, // collateral index
            60_000e18, // Dollar amount
            59_000e18, // min amount of Dollars to mint
            60_000e18 // max collateral to send
        );
    }

    function testMintDollar_ShouldMintDollars() public {
        vm.prank(admin);
        ubiquityPoolFacetV2.setPriceThresholds(
            1000000, // mint threshold
            990000 // redeem threshold
        );

        // balances before
        assertEq(collateralToken.balanceOf(address(ubiquityPoolFacetV2)), 0);
        assertEq(dollarToken.balanceOf(user), 0);

        vm.prank(user);
        (
            uint256 totalDollarMint,
            uint256 collateralNeeded
        ) = ubiquityPoolFacetV2.mintDollar(
                0, // collateral index
                100e18, // Dollar amount
                99e18, // min amount of Dollars to mint
                100e18 // max collateral to send
            );
        assertEq(totalDollarMint, 99e18);
        assertEq(collateralNeeded, 100e18);

        // balances after
        assertEq(
            collateralToken.balanceOf(address(ubiquityPoolFacetV2)),
            100e18
        );
        assertEq(dollarToken.balanceOf(user), 99e18);
    }

    function testRedeemDollar_ShouldRevert_IfRedeemingIsPaused() public {
        // admin pauses redeeming
        vm.prank(admin);
        ubiquityPoolFacetV2.toggleMRB(0, 1);

        vm.prank(user);
        vm.expectRevert("Redeeming is paused");
        ubiquityPoolFacetV2.redeemDollar(
            0, // collateral index
            100e18, // Dollar amount
            90e18 // min collateral out
        );
    }

    function testRedeemDollar_ShouldRevert_IfDollarPriceUsdIsTooHigh() public {
        vm.prank(user);
        vm.expectRevert("Dollar price too high");
        ubiquityPoolFacetV2.redeemDollar(
            0, // collateral index
            100e18, // Dollar amount
            90e18 // min collateral out
        );
    }

    function testRedeemDollar_ShouldRevert_OnInsufficientPoolCollateral()
        public
    {
        vm.prank(admin);
        ubiquityPoolFacetV2.setPriceThresholds(
            1000000, // mint threshold
            1000000 // redeem threshold
        );

        vm.prank(user);
        vm.expectRevert("Insufficient pool collateral");
        ubiquityPoolFacetV2.redeemDollar(
            0, // collateral index
            100e18, // Dollar amount
            90e18 // min collateral out
        );
    }

    function testRedeemDollar_ShouldRevert_OnCollateralSlippage() public {
        vm.prank(admin);
        ubiquityPoolFacetV2.setPriceThresholds(
            1000000, // mint threshold
            1000000 // redeem threshold
        );

        // user sends 100 collateral tokens and gets 99 Dollars (-1% mint fee)
        vm.prank(user);
        ubiquityPoolFacetV2.mintDollar(
            0, // collateral index
            100e18, // Dollar amount
            99e18, // min amount of Dollars to mint
            100e18 // max collateral to send
        );

        vm.prank(user);
        vm.expectRevert("Collateral slippage");
        ubiquityPoolFacetV2.redeemDollar(
            0, // collateral index
            100e18, // Dollar amount
            100e18 // min collateral out
        );
    }

    function testRedeemDollar_ShouldRedeemCollateral() public {
        vm.prank(admin);
        ubiquityPoolFacetV2.setPriceThresholds(
            1000000, // mint threshold
            1000000 // redeem threshold
        );

        // user sends 100 collateral tokens and gets 99 Dollars (-1% mint fee)
        vm.prank(user);
        ubiquityPoolFacetV2.mintDollar(
            0, // collateral index
            100e18, // Dollar amount
            99e18, // min amount of Dollars to mint
            100e18 // max collateral to send
        );

        // balances before
        assertEq(dollarToken.balanceOf(user), 99e18);

        vm.prank(user);
        ubiquityPoolFacetV2.redeemDollar(
            0, // collateral index
            99e18, // Dollar amount
            90e18 // min collateral out
        );

        // balances after
        assertEq(dollarToken.balanceOf(user), 0);
    }

    function testCollectRedemption_ShouldRevert_IfRedeemingIsPaused() public {
        // admin pauses redeeming
        vm.prank(admin);
        ubiquityPoolFacetV2.toggleMRB(0, 1);

        vm.prank(user);
        vm.expectRevert("Redeeming is paused");
        ubiquityPoolFacetV2.collectRedemption(0);
    }

    function testCollectRedemption_ShouldRevert_IfNotEnoughBlocksHaveBeenMined()
        public
    {
        vm.prank(user);
        vm.expectRevert("Too soon");
        ubiquityPoolFacetV2.collectRedemption(0);
    }

    function testCollectRedemption_ShouldCollectRedemption() public {
        vm.prank(admin);
        ubiquityPoolFacetV2.setPriceThresholds(
            1000000, // mint threshold
            1000000 // redeem threshold
        );

        // user sends 100 collateral tokens and gets 99 Dollars (-1% mint fee)
        vm.prank(user);
        ubiquityPoolFacetV2.mintDollar(
            0, // collateral index
            100e18, // Dollar amount
            99e18, // min amount of Dollars to mint
            100e18 // max collateral to send
        );

        // user redeems 99 Dollars for collateral
        vm.prank(user);
        ubiquityPoolFacetV2.redeemDollar(
            0, // collateral index
            99e18, // Dollar amount
            90e18 // min collateral out
        );

        // wait 3 blocks for collecting redemption to become active
        vm.roll(3);

        // balances before
        assertEq(
            collateralToken.balanceOf(address(ubiquityPoolFacetV2)),
            100e18
        );
        assertEq(collateralToken.balanceOf(user), 0);

        vm.prank(user);
        uint collateralAmount = ubiquityPoolFacetV2.collectRedemption(0);
        assertEq(collateralAmount, 97.02e18); // $99 - 2% redemption fee

        // balances after
        assertEq(
            collateralToken.balanceOf(address(ubiquityPoolFacetV2)),
            2.98e18
        );
        assertEq(collateralToken.balanceOf(user), 97.02e18);
    }

    //=========================
    // AMO minters functions
    //=========================

    function testAmoMinterBorrow_ShouldRevert_IfBorrowingIsPaused() public {
        // admin pauses borrowing by AMOs
        vm.prank(admin);
        ubiquityPoolFacetV2.toggleMRB(0, 2);

        // Dollar AMO minter tries to borrow collateral
        vm.prank(address(dollarAmoMinter));
        vm.expectRevert("Borrowing is paused");
        ubiquityPoolFacetV2.amoMinterBorrow(1);
    }

    function testAmoMinterBorrow_ShouldRevert_IfCollateralIsDisabled() public {
        // admin disables collateral
        vm.prank(admin);
        ubiquityPoolFacetV2.toggleCollateral(0);

        // Dollar AMO minter tries to borrow collateral
        vm.prank(address(dollarAmoMinter));
        vm.expectRevert("Collateral disabled");
        ubiquityPoolFacetV2.amoMinterBorrow(1);
    }

    function testAmoMinterBorrow_ShouldBorrowCollateral() public {
        // mint 100 collateral tokens to the pool
        collateralToken.mint(address(ubiquityPoolFacetV2), 100e18);

        assertEq(
            collateralToken.balanceOf(address(ubiquityPoolFacetV2)),
            100e18
        );
        assertEq(collateralToken.balanceOf(address(dollarAmoMinter)), 0);

        vm.prank(address(dollarAmoMinter));
        ubiquityPoolFacetV2.amoMinterBorrow(100e18);

        assertEq(collateralToken.balanceOf(address(ubiquityPoolFacetV2)), 0);
        assertEq(collateralToken.balanceOf(address(dollarAmoMinter)), 100e18);
    }

    //========================
    // Restricted functions
    //========================

    function testAddAmoMinter_ShouldRevert_IfAmoMinterIsZeroAddress() public {
        vm.startPrank(admin);

        vm.expectRevert("Zero address detected");
        ubiquityPoolFacetV2.addAmoMinter(address(0));

        vm.stopPrank();
    }

    function testAddAmoMinter_ShouldRevert_IfAmoMinterHasInvalidInterface()
        public
    {
        vm.startPrank(admin);

        vm.expectRevert();
        ubiquityPoolFacetV2.addAmoMinter(address(1));

        vm.stopPrank();
    }

    function testAddAmoMinter_ShouldAddAmoMinter() public {
        vm.startPrank(admin);

        vm.expectEmit(address(ubiquityPoolFacetV2));
        emit AmoMinterAdded(address(dollarAmoMinter));
        ubiquityPoolFacetV2.addAmoMinter(address(dollarAmoMinter));

        vm.stopPrank();
    }

    function testAddCollateralToken_ShouldAddNewTokenAsCollateral() public {
        LibUbiquityPoolV2.CollateralInformation
            memory info = ubiquityPoolFacetV2.collateralInformation(
                address(collateralToken)
            );
        assertEq(info.index, 0);
        assertEq(info.symbol, "CLT");
        assertEq(info.collateralAddress, address(collateralToken));
        assertEq(info.isEnabled, true);
        assertEq(info.missingDecimals, 0);
        assertEq(info.price, 1_000_000);
        assertEq(info.poolCeiling, 50_000e18);
        assertEq(info.mintPaused, false);
        assertEq(info.redeemPaused, false);
        assertEq(info.borrowingPaused, false);
        assertEq(info.mintingFee, 10000);
        assertEq(info.redemptionFee, 20000);
    }

    function testRemoveAmoMinter_ShouldRemoveAmoMinter() public {
        vm.startPrank(admin);

        vm.expectEmit(address(ubiquityPoolFacetV2));
        emit AmoMinterRemoved(address(dollarAmoMinter));
        ubiquityPoolFacetV2.removeAmoMinter(address(dollarAmoMinter));

        vm.stopPrank();
    }

    function testSetCollateralPrice_ShouldSetCollateralPriceInUsd() public {
        vm.startPrank(admin);

        LibUbiquityPoolV2.CollateralInformation
            memory info = ubiquityPoolFacetV2.collateralInformation(
                address(collateralToken)
            );
        assertEq(info.price, 1_000_000);

        uint newCollateralPrice = 1_100_000;
        vm.expectEmit(address(ubiquityPoolFacetV2));
        emit CollateralPriceSet(0, newCollateralPrice);
        ubiquityPoolFacetV2.setCollateralPrice(0, newCollateralPrice);

        info = ubiquityPoolFacetV2.collateralInformation(
            address(collateralToken)
        );
        assertEq(info.price, newCollateralPrice);

        vm.stopPrank();
    }

    function testSetFees_ShouldSetMintAndRedeemFees() public {
        vm.startPrank(admin);

        vm.expectEmit(address(ubiquityPoolFacetV2));
        emit FeesSet(0, 1, 2);
        ubiquityPoolFacetV2.setFees(0, 1, 2);

        vm.stopPrank();
    }

    function testSetPoolCeiling_ShouldSetMaxAmountOfTokensAllowedForCollateral()
        public
    {
        vm.startPrank(admin);

        LibUbiquityPoolV2.CollateralInformation
            memory info = ubiquityPoolFacetV2.collateralInformation(
                address(collateralToken)
            );
        assertEq(info.poolCeiling, 50_000e18);

        vm.expectEmit(address(ubiquityPoolFacetV2));
        emit PoolCeilingSet(0, 10_000e18);
        ubiquityPoolFacetV2.setPoolCeiling(0, 10_000e18);

        info = ubiquityPoolFacetV2.collateralInformation(
            address(collateralToken)
        );
        assertEq(info.poolCeiling, 10_000e18);

        vm.stopPrank();
    }

    function testSetPriceThresholds_ShouldSetPriceThresholds() public {
        vm.startPrank(admin);

        vm.expectEmit(address(ubiquityPoolFacetV2));
        emit PriceThresholdsSet(1010000, 990000);
        ubiquityPoolFacetV2.setPriceThresholds(1010000, 990000);

        vm.stopPrank();
    }

    function testSetRedemptionDelay_ShouldSetRedemptionDelayInBlocks() public {
        vm.startPrank(admin);

        vm.expectEmit(address(ubiquityPoolFacetV2));
        emit RedemptionDelaySet(2);
        ubiquityPoolFacetV2.setRedemptionDelay(2);

        vm.stopPrank();
    }

    function testToggleCollateral_ShouldToggleCollateral() public {
        vm.startPrank(admin);

        LibUbiquityPoolV2.CollateralInformation
            memory info = ubiquityPoolFacetV2.collateralInformation(
                address(collateralToken)
            );
        assertEq(info.isEnabled, true);

        vm.expectEmit(address(ubiquityPoolFacetV2));
        emit CollateralToggled(0, false);
        ubiquityPoolFacetV2.toggleCollateral(0);

        vm.expectRevert("Invalid collateral");
        info = ubiquityPoolFacetV2.collateralInformation(
            address(collateralToken)
        );

        vm.stopPrank();
    }

    function testToggleMRB_ShouldToggleMinting() public {
        vm.startPrank(admin);

        uint collateralIndex = 0;
        uint8 toggleIndex = 0;

        LibUbiquityPoolV2.CollateralInformation
            memory info = ubiquityPoolFacetV2.collateralInformation(
                address(collateralToken)
            );
        assertEq(info.mintPaused, false);

        vm.expectEmit(address(ubiquityPoolFacetV2));
        emit MRBToggled(collateralIndex, toggleIndex);
        ubiquityPoolFacetV2.toggleMRB(collateralIndex, toggleIndex);

        info = ubiquityPoolFacetV2.collateralInformation(
            address(collateralToken)
        );
        assertEq(info.mintPaused, true);

        vm.stopPrank();
    }

    function testToggleMRB_ShouldToggleRedeeming() public {
        vm.startPrank(admin);

        uint collateralIndex = 0;
        uint8 toggleIndex = 1;

        LibUbiquityPoolV2.CollateralInformation
            memory info = ubiquityPoolFacetV2.collateralInformation(
                address(collateralToken)
            );
        assertEq(info.redeemPaused, false);

        vm.expectEmit(address(ubiquityPoolFacetV2));
        emit MRBToggled(collateralIndex, toggleIndex);
        ubiquityPoolFacetV2.toggleMRB(collateralIndex, toggleIndex);

        info = ubiquityPoolFacetV2.collateralInformation(
            address(collateralToken)
        );
        assertEq(info.redeemPaused, true);

        vm.stopPrank();
    }

    function testToggleMRB_ShouldToggleBorrowingByAmoMinter() public {
        vm.startPrank(admin);

        uint collateralIndex = 0;
        uint8 toggleIndex = 2;

        LibUbiquityPoolV2.CollateralInformation
            memory info = ubiquityPoolFacetV2.collateralInformation(
                address(collateralToken)
            );
        assertEq(info.borrowingPaused, false);

        vm.expectEmit(address(ubiquityPoolFacetV2));
        emit MRBToggled(collateralIndex, toggleIndex);
        ubiquityPoolFacetV2.toggleMRB(collateralIndex, toggleIndex);

        info = ubiquityPoolFacetV2.collateralInformation(
            address(collateralToken)
        );
        assertEq(info.borrowingPaused, true);

        vm.stopPrank();
    }
}
