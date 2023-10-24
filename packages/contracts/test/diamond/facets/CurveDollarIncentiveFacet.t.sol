// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ManagerFacet} from "../../../src/dollar/facets/ManagerFacet.sol";
import {UbiquityDollarToken} from "../../../src/dollar/core/UbiquityDollarToken.sol";
import {TWAPOracleDollar3poolFacet} from "../../../src/dollar/facets/TWAPOracleDollar3poolFacet.sol";
import {CurveDollarIncentiveFacet} from "../../../src/dollar/facets/CurveDollarIncentiveFacet.sol";
import {IERC20Ubiquity} from "../../../src/dollar/interfaces/IERC20Ubiquity.sol";
import {MockTWAPOracleDollar3pool} from "../../../src/dollar/mocks/MockTWAPOracleDollar3pool.sol";
import "../DiamondTestSetup.sol";
import "forge-std/Test.sol";

contract CurveDollarIncentiveTest is DiamondTestSetup {
    address stableSwapMetaPoolAddress = address(0x123);
    address secondAccount = address(0x4);
    address thirdAccount = address(0x5);
    address mockReceiver = address(0x111);
    address mockSender = address(0x222);
    address managerAddr = address(0x333);

    address twapOracleAddress;

    event ExemptAddressUpdate(address indexed _account, bool _isExempt);

    function setUp() public override {
        super.setUp();

        twapOracleAddress = address(diamond);

        vm.startPrank(admin);
        accessControlFacet.grantRole(CURVE_DOLLAR_MANAGER_ROLE, managerAddr);
        vm.stopPrank();
    }

    function mockTwapFuncs(uint256 _twapPrice) public {
        uint256 TWAP_ORACLE_STORAGE_POSITION = uint256(
            keccak256("diamond.standard.twap.oracle.storage")
        ) - 1;
        uint256 dollarPricePosition = TWAP_ORACLE_STORAGE_POSITION + 2;
        vm.store(
            address(diamond),
            bytes32(dollarPricePosition),
            bytes32(_twapPrice)
        );
    }

    function testIncentivizeShouldRevertWhenCallerNotUAD() public {
        vm.expectRevert("CurveIncentive: Caller is not Ubiquity Dollar");
        curveDollarIncentiveFacet.incentivize(
            address(0x111),
            address(0x112),
            100
        );
    }

    function testIncentivizeShouldRevertIfSenderEqualToReceiver() public {
        vm.startPrank(managerAddr);
        vm.expectRevert("CurveIncentive: cannot send self");
        curveDollarIncentiveFacet.incentivize(
            address(0x111),
            address(0x111),
            100
        );
    }

    function testIncentivizeBuy() public {
        vm.startPrank(admin);

        address stableSwapPoolAddress = managerFacet
            .stableSwapMetaPoolAddress();
        IERC20 governanceToken = IERC20(managerFacet.governanceTokenAddress());
        uint256 amountIn;

        // 1. do nothing if the target address is included to exempt list
        uint256 init_balance = governanceToken.balanceOf(mockReceiver);

        curveDollarIncentiveFacet.setExemptAddress(mockReceiver, true);
        vm.stopPrank();

        vm.prank(managerAddr);
        curveDollarIncentiveFacet.incentivize(
            stableSwapPoolAddress,
            mockReceiver,
            amountIn
        );

        uint256 last_balance = governanceToken.balanceOf(mockReceiver);
        assertEq(last_balance, init_balance);

        // 2. do nothing if buyIncentive is off
        init_balance = governanceToken.balanceOf(mockReceiver);
        vm.startPrank(admin);
        curveDollarIncentiveFacet.setExemptAddress(mockReceiver, false);
        vm.stopPrank();

        vm.prank(managerAddr);
        curveDollarIncentiveFacet.incentivize(
            stableSwapPoolAddress,
            mockReceiver,
            100e18
        );

        last_balance = governanceToken.balanceOf(mockReceiver);
        assertEq(last_balance, init_balance);

        // 3. do nothing if no incentive
        mockTwapFuncs(1e18);
        init_balance = governanceToken.balanceOf(mockReceiver);
        vm.startPrank(admin);
        curveDollarIncentiveFacet.setExemptAddress(mockReceiver, false);
        vm.stopPrank();

        vm.prank(managerAddr);
        curveDollarIncentiveFacet.incentivize(
            stableSwapPoolAddress,
            mockReceiver,
            100e18
        );

        last_balance = governanceToken.balanceOf(mockReceiver);
        assertEq(last_balance, init_balance);

        // 4. mint the incentive amount of tokens to the target address
        init_balance = governanceToken.balanceOf(mockReceiver);
        mockTwapFuncs(5e17);
        vm.prank(managerAddr);
        curveDollarIncentiveFacet.incentivize(
            stableSwapPoolAddress,
            mockReceiver,
            100e18
        );

        last_balance = governanceToken.balanceOf(mockReceiver);
        assertEq(last_balance - init_balance, 0);
    }

    function testIncentivizeSell() public {
        address stableSwapPoolAddress = managerFacet
            .stableSwapMetaPoolAddress();
        address dollarAddress = managerFacet.dollarTokenAddress();
        IERC20 dollarToken = IERC20(dollarAddress);

        // 1. do nothing if the target address is included to exempt list
        uint256 init_balance = dollarToken.balanceOf(mockSender);
        vm.prank(admin);
        curveDollarIncentiveFacet.setExemptAddress(mockSender, true);

        vm.prank(managerAddr);
        curveDollarIncentiveFacet.incentivize(
            mockSender,
            stableSwapPoolAddress,
            100e18
        );

        uint256 last_balance = dollarToken.balanceOf(mockSender);
        assertEq(last_balance, init_balance);

        // 2. do nothing if buyIncentive is off
        init_balance = dollarToken.balanceOf(mockSender);
        vm.startPrank(admin);
        curveDollarIncentiveFacet.setExemptAddress(mockSender, false);
        vm.stopPrank();

        vm.prank(managerAddr);
        curveDollarIncentiveFacet.incentivize(
            mockSender,
            stableSwapPoolAddress,
            100e18
        );

        last_balance = dollarToken.balanceOf(mockSender);
        assertEq(last_balance, init_balance);

        // 3. do nothing if no penalty
        mockTwapFuncs(1e18);
        init_balance = dollarToken.balanceOf(mockSender);
        vm.startPrank(admin);
        curveDollarIncentiveFacet.setExemptAddress(mockSender, false);
        vm.stopPrank();

        vm.prank(managerAddr);
        curveDollarIncentiveFacet.incentivize(
            mockSender,
            stableSwapPoolAddress,
            100e18
        );

        last_balance = dollarToken.balanceOf(mockSender);
        assertEq(last_balance, init_balance);

        // 4. burn the penalty amount of tokens from the target address
        vm.prank(admin);
        UbiquityDollarToken(dollarAddress).mint(mockSender, 10000e18);
        init_balance = dollarToken.balanceOf(mockSender);
        mockTwapFuncs(5e17);

        vm.prank(managerAddr);
        curveDollarIncentiveFacet.incentivize(
            mockSender,
            stableSwapPoolAddress,
            100e18
        );

        last_balance = dollarToken.balanceOf(mockSender);
        assertEq(init_balance - last_balance, 0);
    }

    function testSetExemptAddress_ShouldRevertOrSet_IfAdmin() public {
        address exemptAddress = address(0x123);
        vm.expectRevert("Manager: Caller is not admin");
        curveDollarIncentiveFacet.setExemptAddress(exemptAddress, true);

        assertEq(
            curveDollarIncentiveFacet.isExemptAddress(exemptAddress),
            false
        );
        vm.prank(admin);
        vm.expectEmit(true, true, false, true);
        emit ExemptAddressUpdate(exemptAddress, true);
        curveDollarIncentiveFacet.setExemptAddress(exemptAddress, true);
        assertEq(
            curveDollarIncentiveFacet.isExemptAddress(exemptAddress),
            true
        );
    }

    function testSwitchSellPenalty_ShouldRevertOrSwitch_IfAdmin() public {
        vm.expectRevert("Manager: Caller is not admin");
        curveDollarIncentiveFacet.switchSellPenalty();

        assertEq(curveDollarIncentiveFacet.isSellPenaltyOn(), false);
        vm.prank(admin);
        curveDollarIncentiveFacet.switchSellPenalty();
        assertEq(curveDollarIncentiveFacet.isSellPenaltyOn(), true);
    }

    function testSwitchBuyIncentive_ShouldRevertOrSwitch_IfAdmin() public {
        vm.expectRevert("Manager: Caller is not admin");
        curveDollarIncentiveFacet.switchBuyIncentive();

        assertEq(curveDollarIncentiveFacet.isBuyIncentiveOn(), false);
        vm.prank(admin);
        curveDollarIncentiveFacet.switchBuyIncentive();
        assertEq(curveDollarIncentiveFacet.isBuyIncentiveOn(), true);
    }
}
