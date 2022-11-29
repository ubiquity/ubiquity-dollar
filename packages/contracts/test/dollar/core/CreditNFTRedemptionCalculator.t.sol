// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UbiquityDollarManager} from
    "../../../src/dollar/core/UbiquityDollarManager.sol";
import {CreditNFTRedemptionCalculator} from
    "../../../src/dollar/core/CreditNFTRedemptionCalculator.sol";
import {CreditNFT} from "../../../src/dollar/core/CreditNFT.sol";
import {MockCreditNFT} from "../../../src/dollar/mocks/MockCreditNFT.sol";

import "../../helpers/LocalTestHelper.sol";

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
        MockCreditNFT(
            UbiquityDollarManager(uADManagerAddress)
                .creditNFTAddress()
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
        MockCreditNFT(
            UbiquityDollarManager(uADManagerAddress)
                .creditNFTAddress()
        ).setTotalOutstandingDebt(totalSupply / 2);
        assertEq(
            CreditNFTRedemptionCalculator(couponsForDollarsCalculatorAddress)
                .getCouponAmount(10000),
            40000
        );
    }
}
