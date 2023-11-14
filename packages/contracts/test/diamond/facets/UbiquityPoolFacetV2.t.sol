// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/console.sol";
import {DiamondTestSetup} from "../DiamondTestSetup.sol";
import {IDollarAmoMinter} from "../../../src/dollar/interfaces/IDollarAmoMinter.sol";
import {LibUbiquityPoolV2} from "../../../src/dollar/libraries/LibUbiquityPoolV2.sol";
import {MockERC20} from "../../../src/dollar/mocks/MockERC20.sol";

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

        // init AMO minter
        dollarAmoMinter = new MockDollarAmoMinter();

        // init collateral token
        collateralToken = new MockERC20("COLLATERAL", "CLT", 18);

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

        // add AMO minter
        ubiquityPoolFacetV2.addAmoMinter(address(dollarAmoMinter));

        vm.stopPrank();
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
