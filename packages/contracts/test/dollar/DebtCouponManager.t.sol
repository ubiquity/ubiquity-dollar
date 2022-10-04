// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {UbiquityAlgorithmicDollarManager} from "../../src/dollar/UbiquityAlgorithmicDollarManager.sol";
import {DebtCouponManager} from "../../src/dollar/DebtCouponManager.sol";
import {UARForDollarsCalculator} from "../../src/dollar/UARForDollarsCalculator.sol";
import {UbiquityAutoRedeem} from "../../src/dollar/UbiquityAutoRedeem.sol";
import {MockuADToken} from "../../src/dollar/mocks/MockuADToken.sol";
import {MockDebtCoupon} from "../../src/dollar/mocks/MockDebtCoupon.sol";
import {DebtCoupon} from "../../src/dollar/DebtCoupon.sol";
import {TWAPOracle} from "../../src/dollar/TWAPOracle.sol";

import "../helpers/TestHelper.sol";

contract DebtCouponManagerTest is TestHelper {
    address uADManagerAddress;
    address uADAddress;
    address uARDollarCalculatorAddress;
    address debtCouponManagerAddress;
    uint256 couponLengthBlocks = 100;
    address twapOracleAddress;
    address debtCouponAddress;
    address uGovAddress;
    address autoRedeemTokenAddress;

    function setUp() public {
        uADManagerAddress = helpers_deployUbiquityAlgorithmicDollarManager();

        debtCouponManagerAddress = address(new DebtCouponManager(uADManagerAddress, couponLengthBlocks));
        twapOracleAddress = UbiquityAlgorithmicDollarManager(uADManagerAddress).twapOracleAddress();
        uADAddress = UbiquityAlgorithmicDollarManager(uADManagerAddress).dollarTokenAddress();
        uARDollarCalculatorAddress = UbiquityAlgorithmicDollarManager(uADManagerAddress).uarCalculatorAddress();
        debtCouponAddress = UbiquityAlgorithmicDollarManager(uADManagerAddress).debtCouponAddress();
        uGovAddress = UbiquityAlgorithmicDollarManager(uADManagerAddress).governanceTokenAddress();
        autoRedeemTokenAddress = UbiquityAlgorithmicDollarManager(uADManagerAddress).autoRedeemTokenAddress();
    }

    function mockTwapFuncs(uint256 _twapPrice) public {
        vm.mockCall(twapOracleAddress, abi.encodeWithSelector(TWAPOracle.update.selector), abi.encode());
        vm.mockCall(twapOracleAddress, abi.encodeWithSelector(TWAPOracle.consult.selector), abi.encode(_twapPrice));
    }

    function mockUARCalculatorFuncs(uint256 _uarAmount) public {
        vm.mockCall(uARDollarCalculatorAddress, abi.encodeWithSelector(UARForDollarsCalculator.getUARAmount.selector), abi.encode(_uarAmount));
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
        mockTwapFuncs(2e18);
        vm.expectRevert("Price must be below 1 to mint coupons");
        DebtCouponManager(debtCouponManagerAddress).exchangeDollarsForDebtCoupons(100);

        
        mockTwapFuncs(5e17);
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
        mockTwapFuncs(2e18);
        vm.expectRevert("Price must be below 1 to mint uAR");
        DebtCouponManager(debtCouponManagerAddress).exchangeDollarsForUAR(100);
    }

    function test_exchangeDollarsForUARWorks() public {
        mockTwapFuncs(5e17);
        address mockSender = address(0x123);
        vm.roll(10000);
        vm.startPrank(mockSender);

        // Mint some dollarTokens to mockSender and then approve all
        MockuADToken(uADAddress).mint(mockSender, 10000e18);
        MockuADToken(uADAddress).approve(debtCouponManagerAddress, 10000e18);
        
        mockUARCalculatorFuncs(10e18);
        uint256 uARAmount = DebtCouponManager(debtCouponManagerAddress).exchangeDollarsForUAR(100);
        assertEq(uARAmount, 10e18);
    }

    function test_burnExpiredCouponsForUGOVRevertsIfNotExpired() public {
        vm.roll(1000);
        vm.expectRevert("Coupon has not expired");
        DebtCouponManager(debtCouponManagerAddress).burnExpiredCouponsForUGOV(2000, 1e18);
    }

    function test_burnExpiredCouponsForUGOVRevertsIfNotEnoughBalance() public {
        address mockMessageSender = address(0x123);
        vm.prank(admin);
        MockDebtCoupon(debtCouponAddress).mintCoupons(mockMessageSender, 100, 500);
        vm.roll(1000);
        vm.prank(mockMessageSender);
        vm.expectRevert("User not enough coupons");
        DebtCouponManager(debtCouponManagerAddress).burnExpiredCouponsForUGOV(500, 1e18);
    }

    function test_burnExpiredCouponsForUGOVWorks() public {
        address mockMessageSender = address(0x123);
        uint256 expiryBlockNumber = 500;
        vm.startPrank(admin);
        MockDebtCoupon(debtCouponAddress).mintCoupons(mockMessageSender, 2e18, expiryBlockNumber);
        UbiquityAlgorithmicDollarManager(uADManagerAddress).grantRole(keccak256("UBQ_MINTER_ROLE"), debtCouponManagerAddress);
        vm.stopPrank();
        vm.roll(1000);
        vm.prank(mockMessageSender);
        DebtCouponManager(debtCouponManagerAddress).burnExpiredCouponsForUGOV(expiryBlockNumber, 1e18);
        uint256 uGovBalance = UbiquityGovernance(uGovAddress).balanceOf(mockMessageSender);
        assertEq(uGovBalance, 5e17);
    }

    function test_burnCouponsForAutoRedemptionRevertsIfExpired() public {

        vm.warp(1000);
        vm.expectRevert("Coupon has expired");
        DebtCouponManager(debtCouponManagerAddress).burnCouponsForAutoRedemption(500, 1e18);        
    }

    function test_burnCouponsForAutoRedemptionRevertsIfNotEnoughBalance() public {
        vm.warp(1000);
        vm.expectRevert("User not enough coupons");
        DebtCouponManager(debtCouponManagerAddress).burnCouponsForAutoRedemption(1001, 1e18);  
    }

    function test_burnCouponsForAutoRedemptionWorks() public {
        address mockMessageSender = address(0x123);
        uint256 expiryBlockNumber = 500;
        vm.startPrank(admin);
        MockDebtCoupon(debtCouponAddress).mintCoupons(mockMessageSender, 2e18, expiryBlockNumber);
        UbiquityAlgorithmicDollarManager(uADManagerAddress).grantRole(keccak256("UBQ_MINTER_ROLE"), debtCouponManagerAddress);
        vm.stopPrank();
        vm.roll(1000);
        vm.prank(mockMessageSender);
        DebtCouponManager(debtCouponManagerAddress).burnCouponsForAutoRedemption(expiryBlockNumber, 1e18);
        uint256 redeemBalance = UbiquityAutoRedeem(autoRedeemTokenAddress).balanceOf(mockMessageSender);
        assertEq(redeemBalance, 1e18);        
    }

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
