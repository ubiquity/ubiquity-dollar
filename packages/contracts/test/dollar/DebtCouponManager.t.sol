// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {UbiquityAlgorithmicDollarManager} from "../../src/dollar/UbiquityAlgorithmicDollarManager.sol";
import {DebtCouponManager} from "../../src/dollar/DebtCouponManager.sol";
import {MockuADToken} from "../../src/dollar/mocks/MockuADToken.sol";
import {DebtCoupon} from "../../src/dollar/DebtCoupon.sol";
import {TWAPOracle} from "../../src/dollar/TWAPOracle.sol";

import "../helpers/TestHelper.sol";

contract DebtCouponManagerTest is TestHelper {
    address uADManagerAddress;
    address uADAddress;
    address debtCouponManagerAddress;
    uint256 couponLengthBlocks = 100;
    address twapOracleAddress;

    function setUp() public {
        uADManagerAddress = helpers_deployUbiquityAlgorithmicDollarManager();

        debtCouponManagerAddress = address(new DebtCouponManager(uADManagerAddress, couponLengthBlocks));
        twapOracleAddress = UbiquityAlgorithmicDollarManager(uADManagerAddress).twapOracleAddress();
        uADAddress = UbiquityAlgorithmicDollarManager(uADManagerAddress).dollarTokenAddress();
    }

    function mockInternalFuncs(uint256 _twapPrice) public {
        vm.mockCall(twapOracleAddress, abi.encodeWithSelector(TWAPOracle.update.selector), abi.encode());
        vm.mockCall(twapOracleAddress, abi.encodeWithSelector(TWAPOracle.consult.selector), abi.encode(_twapPrice));
    }

    function test_setExpiredCouponConvertionRate() public {
        vm.expectRevert("Caller is not a coupon manager");
        DebtCouponManager(debtCouponManagerAddress).setExpiredCouponConvertionRate(100);

        vm.prank(admin);
        DebtCouponManager(debtCouponManagerAddress).setExpiredCouponConvertionRate(100);
        assertEq(DebtCouponManager(debtCouponManagerAddress).expiredCouponConvertionRate(), 100);
    }

    function test_setCouponLength() public {
        vm.expectRevert("Caller is not a coupon manager");
        DebtCouponManager(debtCouponManagerAddress).setCouponLength(100);

        vm.prank(admin);
        DebtCouponManager(debtCouponManagerAddress).setCouponLength(100);
        assertEq(DebtCouponManager(debtCouponManagerAddress).couponLengthBlocks(), 100);
    }

    function test_exchangeDollarsForDebtCoupons() public {
        mockInternalFuncs(2e18);
        vm.expectRevert("Price must be below 1 to mint coupons");
        DebtCouponManager(debtCouponManagerAddress).exchangeDollarsForDebtCoupons(100);

        
        mockInternalFuncs(5e17);
        address mockSender = address(0x123);
        vm.roll(10000);
        vm.startPrank(mockSender);

        // Mint some dollarTokens to mockSender and then approve all
        MockuADToken(uADAddress).mint(mockSender, 10000e18);
        MockuADToken(uADAddress).approve(debtCouponManagerAddress, 10000e18);
        
        uint256 expiryBlockNumber = DebtCouponManager(debtCouponManagerAddress).exchangeDollarsForDebtCoupons(100);
        assertEq(expiryBlockNumber, 10000 + couponLengthBlocks);

        // TODO: We need to add more asserts here for strong sanitation checks 
        // like check the difference in debtCoupon/dollarToken balance        
    }

    function test_exchangeDollarsForUARRevertsIfPriceHigherThan1Ether() public {
        mockInternalFuncs(2e18);
        vm.expectRevert("Price must be below 1 to mint uAR");
        DebtCouponManager(debtCouponManagerAddress).exchangeDollarsForUAR(100);
    }

    function test_exchangeDollarsForUARWorks() public {
        mockInternalFuncs(5e17);
        address mockSender = address(0x123);
        vm.roll(10000);
        vm.startPrank(mockSender);

        // Mint some dollarTokens to mockSender and then approve all
        MockuADToken(uADAddress).mint(mockSender, 10000e18);
        MockuADToken(uADAddress).approve(debtCouponManagerAddress, 10000e18);
        
        uint256 expiryBlockNumber = DebtCouponManager(debtCouponManagerAddress).exchangeDollarsForUAR(100);
        assertEq(expiryBlockNumber, 10000 + couponLengthBlocks);
    }

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
