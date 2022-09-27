// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {UbiquityAlgorithmicDollarManager} from "../../src/dollar/UbiquityAlgorithmicDollarManager.sol";
import {DebtCoupon} from "../../src/dollar/DebtCoupon.sol";


import "../helpers/TestHelper.sol";

contract DebtCouponTest is TestHelper {
    address uADManagerAddress;
    address debtCouponAddress;

    function setUp() public {
        uADManagerAddress = helpers_deployUbiquityAlgorithmicDollarManager();
        debtCouponAddress = address(new DebtCoupon(uADManagerAddress));
    }

    function test_mintCouponsRevertsIfNotCouponManager() public {}

    function test_mintCouponsWorks() public {}

    function test_burnCouponsRevertsIfNotCouponManager() public {}

    function test_burnCouponRevertsWorks() public {}

    function test_updateTotalDebt() public {}

    function test_getTotalOutstandingDebt() public {}
}