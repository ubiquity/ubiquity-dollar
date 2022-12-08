// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UbiquityAlgorithmicDollarManager} from "../../src/dollar/UbiquityAlgorithmicDollarManager.sol";
import {UbiquityAlgorithmicDollar} from "../../src/dollar/UbiquityAlgorithmicDollar.sol";
import {CouponsForDollarsCalculator} from "../../src/dollar/CouponsForDollarsCalculator.sol";
import {TWAPOracleDollar3pool} from "../../src/dollar/TWAPOracleDollar3pool.sol";
import {DebtCoupon} from "../../src/dollar/DebtCoupon.sol";
import {MockDebtCoupon} from "../../src/dollar/mocks/MockDebtCoupon.sol";
import {CurveUADIncentive} from "../../src/dollar/CurveUADIncentive.sol";

import "../helpers/LocalTestHelper.sol";

contract CurveUADIncentiveTest is LocalTestHelper {
    address uADManagerAddress;
    address curveIncentiveAddress;
    address twapOracleAddress;
    address stableSwapMetaPoolAddress = address(0x123);

    event ExemptAddressUpdate(address indexed _account, bool _isExempt);

    function setUp() public {
        uADManagerAddress = helpers_deployUbiquityAlgorithmicDollarManager();
        curveIncentiveAddress = address(
            new CurveUADIncentive(uADManagerAddress)
        );
        twapOracleAddress = UbiquityAlgorithmicDollarManager(uADManagerAddress)
            .twapOracleAddress();
        vm.prank(admin);
        UbiquityAlgorithmicDollarManager(uADManagerAddress)
            .setStableSwapMetaPoolAddress(stableSwapMetaPoolAddress);
    }

    function mockInternalFuncs(uint256 _twapPrice) public {
        vm.mockCall(
            twapOracleAddress,
            abi.encodeWithSelector(TWAPOracleDollar3pool.update.selector),
            abi.encode()
        );
        vm.mockCall(
            twapOracleAddress,
            abi.encodeWithSelector(TWAPOracleDollar3pool.consult.selector),
            abi.encode(_twapPrice)
        );
    }

    function test_incentivize_revertsIfCallerNotUAD() public {
        vm.expectRevert("CurveIncentive: Caller is not uAD");
        CurveUADIncentive(curveIncentiveAddress).incentivize(
            address(0x111),
            address(0x112),
            admin,
            100
        );
    }

    function test_incentivize_revertsIfSenderEqualToReceiver() public {
        vm.prank(
            UbiquityAlgorithmicDollarManager(uADManagerAddress)
                .dollarTokenAddress()
        );
        vm.expectRevert("CurveIncentive: cannot send self");
        CurveUADIncentive(curveIncentiveAddress).incentivize(
            address(0x111),
            address(0x111),
            admin,
            100
        );
    }

    function test_incentivize_buy() public {
        address stableSwapPoolAddress = UbiquityAlgorithmicDollarManager(
            uADManagerAddress
        ).stableSwapMetaPoolAddress();
        IERC20 govToken = IERC20(
            UbiquityAlgorithmicDollarManager(uADManagerAddress)
                .governanceTokenAddress()
        );
        address uAD_addr = UbiquityAlgorithmicDollarManager(uADManagerAddress)
            .dollarTokenAddress();
        address mockReceiver = address(0x111);

        // 1. do nothing if the target address is included to exempt list
        uint256 init_balance = govToken.balanceOf(mockReceiver);
        vm.prank(admin);
        CurveUADIncentive(curveIncentiveAddress).setExemptAddress(
            mockReceiver,
            true
        );

        vm.prank(uAD_addr);
        CurveUADIncentive(curveIncentiveAddress).incentivize(
            stableSwapPoolAddress,
            mockReceiver,
            address(0),
            100e18
        );

        uint256 last_balance = govToken.balanceOf(mockReceiver);
        assertEq(last_balance, init_balance);

        // 2. do nothing if buyIncentive is off
        init_balance = govToken.balanceOf(mockReceiver);
        vm.startPrank(admin);
        CurveUADIncentive(curveIncentiveAddress).setExemptAddress(
            mockReceiver,
            false
        );
        CurveUADIncentive(curveIncentiveAddress).switchBuyIncentive();
        vm.stopPrank();

        vm.prank(uAD_addr);
        CurveUADIncentive(curveIncentiveAddress).incentivize(
            stableSwapPoolAddress,
            mockReceiver,
            address(0),
            100e18
        );

        last_balance = govToken.balanceOf(mockReceiver);
        assertEq(last_balance, init_balance);

        // 3. do nothing if no incentive
        mockInternalFuncs(1e18);
        init_balance = govToken.balanceOf(mockReceiver);
        vm.startPrank(admin);
        CurveUADIncentive(curveIncentiveAddress).setExemptAddress(
            mockReceiver,
            false
        );
        CurveUADIncentive(curveIncentiveAddress).switchBuyIncentive();
        vm.stopPrank();

        vm.prank(uAD_addr);
        CurveUADIncentive(curveIncentiveAddress).incentivize(
            stableSwapPoolAddress,
            mockReceiver,
            address(0),
            100e18
        );

        last_balance = govToken.balanceOf(mockReceiver);
        assertEq(last_balance, init_balance);

        // 4. mint the incentive amount of tokens to the target address
        init_balance = govToken.balanceOf(mockReceiver);
        mockInternalFuncs(5e17);
        vm.prank(admin);
        UbiquityAlgorithmicDollarManager(uADManagerAddress).grantRole(
            keccak256("UBQ_MINTER_ROLE"),
            curveIncentiveAddress
        );
        vm.prank(uAD_addr);
        CurveUADIncentive(curveIncentiveAddress).incentivize(
            stableSwapPoolAddress,
            mockReceiver,
            address(0),
            100e18
        );

        last_balance = govToken.balanceOf(mockReceiver);
        assertEq(last_balance - init_balance, 50e18);
    }

    function test_incentivize_sell() public {
        address stableSwapPoolAddress = UbiquityAlgorithmicDollarManager(
            uADManagerAddress
        ).stableSwapMetaPoolAddress();
        IERC20 govToken = IERC20(
            UbiquityAlgorithmicDollarManager(uADManagerAddress)
                .governanceTokenAddress()
        );
        address uAD_addr = UbiquityAlgorithmicDollarManager(uADManagerAddress)
            .dollarTokenAddress();
        IERC20 uADToken = IERC20(uAD_addr);
        address mockSender = address(0x222);

        // 1. do nothing if the target address is included to exempt list
        uint256 init_balance = uADToken.balanceOf(mockSender);
        vm.prank(admin);
        CurveUADIncentive(curveIncentiveAddress).setExemptAddress(
            mockSender,
            true
        );

        vm.prank(uAD_addr);
        CurveUADIncentive(curveIncentiveAddress).incentivize(
            mockSender,
            stableSwapPoolAddress,
            address(0),
            100e18
        );

        uint256 last_balance = uADToken.balanceOf(mockSender);
        assertEq(last_balance, init_balance);

        // 2. do nothing if buyIncentive is off
        init_balance = uADToken.balanceOf(mockSender);
        vm.startPrank(admin);
        CurveUADIncentive(curveIncentiveAddress).setExemptAddress(
            mockSender,
            false
        );
        CurveUADIncentive(curveIncentiveAddress).switchSellPenalty();
        vm.stopPrank();

        vm.prank(uAD_addr);
        CurveUADIncentive(curveIncentiveAddress).incentivize(
            mockSender,
            stableSwapPoolAddress,
            address(0),
            100e18
        );

        last_balance = uADToken.balanceOf(mockSender);
        assertEq(last_balance, init_balance);

        // 3. do nothing if no penalty
        mockInternalFuncs(1e18);
        init_balance = uADToken.balanceOf(mockSender);
        vm.startPrank(admin);
        CurveUADIncentive(curveIncentiveAddress).setExemptAddress(
            mockSender,
            false
        );
        CurveUADIncentive(curveIncentiveAddress).switchSellPenalty();
        vm.stopPrank();

        vm.prank(uAD_addr);
        CurveUADIncentive(curveIncentiveAddress).incentivize(
            mockSender,
            stableSwapPoolAddress,
            address(0),
            100e18
        );

        last_balance = uADToken.balanceOf(mockSender);
        assertEq(last_balance, init_balance);

        // 4. burn the penalty amount of tokens from the target address
        vm.prank(admin);
        UbiquityAlgorithmicDollar(uAD_addr).mint(mockSender, 10000e18);
        init_balance = uADToken.balanceOf(mockSender);
        assertEq(init_balance, 10000e18);
        mockInternalFuncs(5e17);
        vm.prank(uAD_addr);
        CurveUADIncentive(curveIncentiveAddress).incentivize(
            mockSender,
            stableSwapPoolAddress,
            address(0),
            100e18
        );

        last_balance = uADToken.balanceOf(mockSender);
        assertEq(init_balance - last_balance, 50e18);
    }

    function test_setExemptAddress() public {
        address exemptAddress = address(0x123);
        vm.expectRevert("CurveIncentive: not admin");
        CurveUADIncentive(curveIncentiveAddress).setExemptAddress(
            exemptAddress,
            true
        );

        assertEq(
            CurveUADIncentive(curveIncentiveAddress).isExemptAddress(
                exemptAddress
            ),
            false
        );
        vm.prank(admin);
        vm.expectEmit(true, true, false, true);
        emit ExemptAddressUpdate(exemptAddress, true);
        CurveUADIncentive(curveIncentiveAddress).setExemptAddress(
            exemptAddress,
            true
        );
        assertEq(
            CurveUADIncentive(curveIncentiveAddress).isExemptAddress(
                exemptAddress
            ),
            true
        );
    }

    function test_switchSellPenalty() public {
        vm.expectRevert("CurveIncentive: not admin");
        CurveUADIncentive(curveIncentiveAddress).switchSellPenalty();

        assertEq(
            CurveUADIncentive(curveIncentiveAddress).isSellPenaltyOn(),
            true
        );
        vm.prank(admin);
        CurveUADIncentive(curveIncentiveAddress).switchSellPenalty();
        assertEq(
            CurveUADIncentive(curveIncentiveAddress).isSellPenaltyOn(),
            false
        );
    }

    function test_switchBuyIncentive() public {
        vm.expectRevert("CurveIncentive: not admin");
        CurveUADIncentive(curveIncentiveAddress).switchBuyIncentive();

        assertEq(
            CurveUADIncentive(curveIncentiveAddress).isBuyIncentiveOn(),
            true
        );
        vm.prank(admin);
        CurveUADIncentive(curveIncentiveAddress).switchBuyIncentive();
        assertEq(
            CurveUADIncentive(curveIncentiveAddress).isBuyIncentiveOn(),
            false
        );
    }
}
