// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UbiquityAlgorithmicDollarManager} from "../../src/dollar/UbiquityAlgorithmicDollarManager.sol";
import {CouponsForDollarsCalculator} from "../../src/dollar/CouponsForDollarsCalculator.sol";
import {DebtCoupon} from "../../src/dollar/DebtCoupon.sol";
import {MockDebtCoupon} from "../../src/dollar/mocks/MockDebtCoupon.sol";

import "../helpers/TestHelper.sol";

contract CouponsForDollarsCalculatorTest is TestHelper {
    address uADManagerAddress;
    address couponsForDollarsCalculatorAddress;

    function setUp() public {
        uADManagerAddress = helpers_deployUbiquityAlgorithmicDollarManager();
        couponsForDollarsCalculatorAddress = address(new CouponsForDollarsCalculator(uADManagerAddress));
    }

    function test_getCouponAmount_revertsIfDebtTooHigh() public {
        uint256 totalSupply =
            IERC20(UbiquityAlgorithmicDollarManager(uADManagerAddress).dollarTokenAddress()).totalSupply();
        MockDebtCoupon(UbiquityAlgorithmicDollarManager(uADManagerAddress).debtCouponAddress()).setTotalOutstandingDebt(
            totalSupply + 1
        );

        vm.expectRevert("Coupon to dollar: DEBT_TOO_HIGH");
        CouponsForDollarsCalculator(couponsForDollarsCalculatorAddress).getCouponAmount(0);
    }

    function test_getCouponAmount() public {
        uint256 totalSupply =
            IERC20(UbiquityAlgorithmicDollarManager(uADManagerAddress).dollarTokenAddress()).totalSupply();
        MockDebtCoupon(UbiquityAlgorithmicDollarManager(uADManagerAddress).debtCouponAddress()).setTotalOutstandingDebt(
            totalSupply / 2
        );
        assertEq(CouponsForDollarsCalculator(couponsForDollarsCalculatorAddress).getCouponAmount(10000), 40000);
    }
}
