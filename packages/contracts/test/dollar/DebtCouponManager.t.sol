// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {UbiquityAlgorithmicDollarManager} from "../../src/dollar/UbiquityAlgorithmicDollarManager.sol";
import {DebtCouponManager} from "../../src/dollar/DebtCouponManager.sol";
import {DebtCoupon} from "../../src/dollar/DebtCoupon.sol";

import "../helpers/TestHelper.sol";

contract DebtCouponManagerTest is TestHelper {
    address uADManagerAddress;


    function setUp() public {
        uADManagerAddress = helpers_deployUbiquityAlgorithmicDollarManager();
    }

    function test_setExpiredCouponConvertionRate() public {}

    function test_setCouponLength() public {}

    function test_exchangeDollarsForDebtCoupons() public {}

    function test_exchangeDollarsForUARRevertsIfPriceHigherThan1Ether() public {}

    function test_exchangeDollarsForUARWorks() public {}

    function test_getCouponsReturnedForDollars() public {}

    function test_getUARReturnedForDollars() public {}

    function test_burnExpiredCouponsForUGOVRevertsIfNotExpired() public {}

    function test_burnExpiredCouponsForUGOVRevertsIfNotEnoughBalance() public {}

    function test_burnExpiredCouponsForUGOVWorks() public {}

        function test_burnCouponsForAutoRedemptionRevertsIfNotExpired() public {}

    function test_burnCouponsForAutoRedemptionRevertsIfNotEnoughBalance() public {}

    function test_burnCouponsForAutoRedemptionWorks() public {}

    function test_burnAutoRedeemTokensForDollarsRevertsIfPriceLowerThan1Ether() public {}

    function test_burnAutoRedeemTokensForDollarsIfNotEnoughBalance() public {}

    function test_burnAutoRedeemTokensForDollarsWorks() public {}

    function test_redeemCouponsRevertsIfPriceLowerThan1Ether() public {}

    function test_redeemCouponsRevertsIfCouponExpired() public {}

    function test_redeemCouponsRevertsIfNotEnoughBalance() public {}

    function test_redeemCouponsRevertsIfNotEnoughUAD() public {}

    function test_redeemCouponsRevertsIfZeroAmountOfUAD() public {}

    function test_mintClaimableDollars() public {}
}
