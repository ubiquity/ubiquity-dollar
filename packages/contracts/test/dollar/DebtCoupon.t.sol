// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {UbiquityAlgorithmicDollarManager} from
    "../../src/dollar/UbiquityAlgorithmicDollarManager.sol";
import {DebtCoupon} from "../../src/dollar/DebtCoupon.sol";

import "../helpers/LocalTestHelper.sol";

contract DebtCouponTest is LocalTestHelper {
    address uADManagerAddress;
    address debtCouponAddress;

    event MintedCoupons(address recipient, uint256 expiryBlock, uint256 amount);

    event BurnedCoupons(
        address couponHolder, uint256 expiryBlock, uint256 amount
    );

    function setUp() public {
        uADManagerAddress = helpers_deployUbiquityAlgorithmicDollarManager();
        debtCouponAddress = address(new DebtCoupon(uADManagerAddress));
    }

    function test_mintCouponsRevertsIfNotCouponManager() public {
        vm.expectRevert("Caller is not a coupon manager");
        DebtCoupon(debtCouponAddress).mintCoupons(address(0x123), 1, 100);
    }

    function test_mintCouponsWorks() public {
        address receiver = address(0x123);
        uint256 expiryBlockNumber = 100;
        uint256 mintAmount = 1;

        uint256 init_balance =
            DebtCoupon(debtCouponAddress).balanceOf(receiver, expiryBlockNumber);
        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit MintedCoupons(receiver, expiryBlockNumber, 1);
        DebtCoupon(debtCouponAddress).mintCoupons(
            receiver, mintAmount, expiryBlockNumber
        );
        uint256 last_balance =
            DebtCoupon(debtCouponAddress).balanceOf(receiver, expiryBlockNumber);
        assertEq(last_balance - init_balance, mintAmount);

        uint256[] memory holderTokens =
            DebtCoupon(debtCouponAddress).holderTokens(receiver);
        assertEq(holderTokens[0], expiryBlockNumber);
    }

    function test_burnCouponsRevertsIfNotCouponManager() public {
        vm.expectRevert("Caller is not a coupon manager");
        DebtCoupon(debtCouponAddress).burnCoupons(address(0x123), 1, 100);
    }

    function test_burnCouponRevertsWorks() public {
        address couponOwner = address(0x123);
        uint256 expiryBlockNumber = 100;
        uint256 burnAmount = 1;

        vm.prank(admin);
        DebtCoupon(debtCouponAddress).mintCoupons(
            couponOwner, 10, expiryBlockNumber
        );
        uint256 init_balance = DebtCoupon(debtCouponAddress).balanceOf(
            couponOwner, expiryBlockNumber
        );
        vm.prank(couponOwner);
        DebtCoupon(debtCouponAddress).setApprovalForAll(admin, true);
        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit BurnedCoupons(couponOwner, expiryBlockNumber, 1);
        DebtCoupon(debtCouponAddress).burnCoupons(
            couponOwner, burnAmount, expiryBlockNumber
        );
        uint256 last_balance = DebtCoupon(debtCouponAddress).balanceOf(
            couponOwner, expiryBlockNumber
        );
        assertEq(init_balance - last_balance, burnAmount);
    }

    function test_updateTotalDebt() public {
        vm.startPrank(admin);
        DebtCoupon(debtCouponAddress).mintCoupons(address(0x111), 10, 10000); // 10 -> amount, 10000 -> expiryBlockNumber
        DebtCoupon(debtCouponAddress).mintCoupons(address(0x222), 10, 20000);
        DebtCoupon(debtCouponAddress).mintCoupons(address(0x333), 10, 30000);
        vm.stopPrank();

        // sets block.number
        vm.roll(15000);
        DebtCoupon(debtCouponAddress).updateTotalDebt();
        uint256 outStandingTotalDebt =
            DebtCoupon(debtCouponAddress).getTotalOutstandingDebt();
        assertEq(outStandingTotalDebt, 20);
    }

    function test_getTotalOutstandingDebt() public {
        vm.startPrank(admin);
        DebtCoupon(debtCouponAddress).mintCoupons(address(0x111), 10, 10000); // 10 -> amount, 10000 -> expiryBlockNumber
        DebtCoupon(debtCouponAddress).mintCoupons(address(0x222), 10, 20000);
        DebtCoupon(debtCouponAddress).mintCoupons(address(0x333), 10, 30000);
        vm.stopPrank();

        // sets block.number
        vm.roll(25000);
        DebtCoupon(debtCouponAddress).updateTotalDebt();
        uint256 outStandingTotalDebt =
            DebtCoupon(debtCouponAddress).getTotalOutstandingDebt();
        assertEq(outStandingTotalDebt, 10);
    }
}
