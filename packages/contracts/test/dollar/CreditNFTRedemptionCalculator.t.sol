// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UbiquityDollarManager} from
    "../../src/dollar/UbiquityDollarManager.sol";
import {CreditNFTRedemptionCalculator} from
    "../../src/dollar/CreditNFTRedemptionCalculator.sol";
import {DebtCoupon} from "../../src/dollar/DebtCoupon.sol";
import {MockDebtCoupon} from "../../src/dollar/mocks/MockDebtCoupon.sol";

import "../helpers/LocalTestHelper.sol";

contract CreditNFTRedemptionCalculatorTest is LocalTestHelper {
    address uADManagerAddress;
    address couponsForDollarsCalculatorAddress;

    function setUp() public {
        uADManagerAddress = helpers_deployUbiquityDollarManager();
        couponsForDollarsCalculatorAddress =
            address(new CreditNFTRedemptionCalculator(uADManagerAddress));
    }

    function test_getCouponAmount_revertsIfDebtTooHigh() public {
        uint256 totalSupply = IERC20(
            UbiquityDollarManager(uADManagerAddress)
                .dollarTokenAddress()
        ).totalSupply();
        MockDebtCoupon(
            UbiquityDollarManager(uADManagerAddress)
                .debtCouponAddress()
        ).setTotalOutstandingDebt(totalSupply + 1);

        vm.expectRevert("Coupon to dollar: DEBT_TOO_HIGH");
        CreditNFTRedemptionCalculator(couponsForDollarsCalculatorAddress)
            .getCouponAmount(0);
    }

    function test_getCouponAmount() public {
        uint256 totalSupply = IERC20(
            UbiquityDollarManager(uADManagerAddress)
                .dollarTokenAddress()
        ).totalSupply();
        MockDebtCoupon(
            UbiquityDollarManager(uADManagerAddress)
                .debtCouponAddress()
        ).setTotalOutstandingDebt(totalSupply / 2);
        assertEq(
            CreditNFTRedemptionCalculator(couponsForDollarsCalculatorAddress)
                .getCouponAmount(10000),
            40000
        );
    }
}
