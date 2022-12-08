// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {UbiquityAlgorithmicDollarManager} from "../../src/dollar/UbiquityAlgorithmicDollarManager.sol";
import {DebtCouponManager} from "../../src/dollar/DebtCouponManager.sol";
import {UARForDollarsCalculator} from "../../src/dollar/UARForDollarsCalculator.sol";
import {DollarMintingCalculator} from "../../src/dollar/DollarMintingCalculator.sol";
import {UbiquityAutoRedeem} from "../../src/dollar/UbiquityAutoRedeem.sol";
import {ExcessDollarsDistributor} from "../../src/dollar/ExcessDollarsDistributor.sol";
import {DebtCoupon} from "../../src/dollar/DebtCoupon.sol";
import {TWAPOracleDollar3pool} from "../../src/dollar/TWAPOracleDollar3pool.sol";

import {MockDollarToken} from "../../src/dollar/mocks/MockDollarToken.sol";
import {MockDebtCoupon} from "../../src/dollar/mocks/MockDebtCoupon.sol";
import {MockAutoRedeem} from "../../src/dollar/mocks/MockAutoRedeem.sol";

import "../helpers/LocalTestHelper.sol";

contract DebtCouponManagerTest is LocalTestHelper {
    address uADManagerAddress;
    address uADAddress;
    address uARDollarCalculatorAddress;
    address debtCouponManagerAddress;
    uint256 couponLengthBlocks = 100;
    address twapOracleAddress;
    address debtCouponAddress;
    address uGovAddress;
    address autoRedeemTokenAddress;
    address dollarMintingCalculatorAddress;

    function setUp() public {
        uADManagerAddress = helpers_deployUbiquityAlgorithmicDollarManager();

        debtCouponManagerAddress = address(
            new DebtCouponManager(uADManagerAddress, couponLengthBlocks)
        );
        twapOracleAddress = UbiquityAlgorithmicDollarManager(uADManagerAddress)
            .twapOracleAddress();
        uADAddress = UbiquityAlgorithmicDollarManager(uADManagerAddress)
            .dollarTokenAddress();
        uARDollarCalculatorAddress = UbiquityAlgorithmicDollarManager(
            uADManagerAddress
        ).uarCalculatorAddress();
        debtCouponAddress = UbiquityAlgorithmicDollarManager(uADManagerAddress)
            .debtCouponAddress();
        uGovAddress = UbiquityAlgorithmicDollarManager(uADManagerAddress)
            .governanceTokenAddress();
        autoRedeemTokenAddress = UbiquityAlgorithmicDollarManager(
            uADManagerAddress
        ).autoRedeemTokenAddress();
        dollarMintingCalculatorAddress = UbiquityAlgorithmicDollarManager(
            uADManagerAddress
        ).dollarMintingCalculatorAddress();
    }

    function mockTwapFuncs(uint256 _twapPrice) public {
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

    function mockUARCalculatorFuncs(uint256 _uarAmount) public {
        vm.mockCall(
            uARDollarCalculatorAddress,
            abi.encodeWithSelector(
                UARForDollarsCalculator.getUARAmount.selector
            ),
            abi.encode(_uarAmount)
        );
    }

    function mockDollarMintingCalcFuncs(uint256 _dollarsToMint) public {
        vm.mockCall(
            dollarMintingCalculatorAddress,
            abi.encodeWithSelector(
                DollarMintingCalculator.getDollarsToMint.selector
            ),
            abi.encode(_dollarsToMint)
        );
    }

    function helperDeployExcessDollarCalculator(
        address _excessDollarsDistributor
    ) public {
        vm.prank(admin);
        UbiquityAlgorithmicDollarManager(uADManagerAddress)
            .setExcessDollarsDistributor(
                debtCouponManagerAddress,
                _excessDollarsDistributor
            );
    }

    function test_setExpiredCouponConversionRate() public {
        vm.expectRevert("Caller is not a coupon manager");
        DebtCouponManager(debtCouponManagerAddress)
            .setExpiredCouponConversionRate(100);

        vm.prank(admin);
        DebtCouponManager(debtCouponManagerAddress)
            .setExpiredCouponConversionRate(100);
        assertEq(
            DebtCouponManager(debtCouponManagerAddress)
                .expiredCouponConversionRate(),
            100
        );
    }

    function test_setCouponLength() public {
        vm.expectRevert("Caller is not a coupon manager");
        DebtCouponManager(debtCouponManagerAddress).setCouponLength(100);

        vm.prank(admin);
        DebtCouponManager(debtCouponManagerAddress).setCouponLength(100);
        assertEq(
            DebtCouponManager(debtCouponManagerAddress).couponLengthBlocks(),
            100
        );
    }

    function test_exchangeDollarsForDebtCoupons() public {
        mockTwapFuncs(2e18);
        vm.expectRevert("Price must be below 1 to mint coupons");
        DebtCouponManager(debtCouponManagerAddress)
            .exchangeDollarsForDebtCoupons(100);

        mockTwapFuncs(5e17);
        address mockSender = address(0x123);
        vm.roll(10000);
        vm.startPrank(mockSender);

        // Mint some dollarTokens to mockSender and then approve all
        MockDollarToken(uADAddress).mint(mockSender, 10000e18);
        MockDollarToken(uADAddress).approve(debtCouponManagerAddress, 10000e18);

        uint256 expiryBlockNumber = DebtCouponManager(debtCouponManagerAddress)
            .exchangeDollarsForDebtCoupons(100);
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
        MockDollarToken(uADAddress).mint(mockSender, 10000e18);
        MockDollarToken(uADAddress).approve(debtCouponManagerAddress, 10000e18);

        mockUARCalculatorFuncs(10e18);
        uint256 uARAmount = DebtCouponManager(debtCouponManagerAddress)
            .exchangeDollarsForUAR(100);
        assertEq(uARAmount, 10e18);
    }

    function test_burnExpiredCouponsForUGOVRevertsIfNotExpired() public {
        vm.roll(1000);
        vm.expectRevert("Coupon has not expired");
        DebtCouponManager(debtCouponManagerAddress).burnExpiredCouponsForUGOV(
            2000,
            1e18
        );
    }

    function test_burnExpiredCouponsForUGOVRevertsIfNotEnoughBalance() public {
        address mockMessageSender = address(0x123);
        vm.prank(admin);
        MockDebtCoupon(debtCouponAddress).mintCoupons(
            mockMessageSender,
            100,
            500
        );
        vm.roll(1000);
        vm.prank(mockMessageSender);
        vm.expectRevert("User not enough coupons");
        DebtCouponManager(debtCouponManagerAddress).burnExpiredCouponsForUGOV(
            500,
            1e18
        );
    }

    function test_burnExpiredCouponsForUGOVWorks() public {
        address mockMessageSender = address(0x123);
        uint256 expiryBlockNumber = 500;
        vm.startPrank(admin);
        MockDebtCoupon(debtCouponAddress).mintCoupons(
            mockMessageSender,
            2e18,
            expiryBlockNumber
        );
        UbiquityAlgorithmicDollarManager(uADManagerAddress).grantRole(
            keccak256("UBQ_MINTER_ROLE"),
            debtCouponManagerAddress
        );
        vm.stopPrank();
        vm.roll(1000);
        vm.prank(mockMessageSender);
        DebtCouponManager(debtCouponManagerAddress).burnExpiredCouponsForUGOV(
            expiryBlockNumber,
            1e18
        );
        uint256 uGovBalance = UbiquityGovernance(uGovAddress).balanceOf(
            mockMessageSender
        );
        assertEq(uGovBalance, 5e17);
    }

    function test_burnCouponsForAutoRedemptionRevertsIfExpired() public {
        vm.warp(1000);
        vm.expectRevert("Coupon has expired");
        DebtCouponManager(debtCouponManagerAddress)
            .burnCouponsForAutoRedemption(500, 1e18);
    }

    function test_burnCouponsForAutoRedemptionRevertsIfNotEnoughBalance()
        public
    {
        vm.warp(1000);
        vm.expectRevert("User not enough coupons");
        DebtCouponManager(debtCouponManagerAddress)
            .burnCouponsForAutoRedemption(1001, 1e18);
    }

    function test_burnCouponsForAutoRedemptionWorks() public {
        address mockMessageSender = address(0x123);
        uint256 expiryBlockNumber = 500;
        vm.startPrank(admin);
        MockDebtCoupon(debtCouponAddress).mintCoupons(
            mockMessageSender,
            2e18,
            expiryBlockNumber
        );
        UbiquityAlgorithmicDollarManager(uADManagerAddress).grantRole(
            keccak256("UBQ_MINTER_ROLE"),
            debtCouponManagerAddress
        );
        vm.stopPrank();
        vm.prank(mockMessageSender);
        vm.warp(expiryBlockNumber - 1);
        DebtCouponManager(debtCouponManagerAddress)
            .burnCouponsForAutoRedemption(expiryBlockNumber, 1e18);
        uint256 redeemBalance = UbiquityAutoRedeem(autoRedeemTokenAddress)
            .balanceOf(mockMessageSender);
        assertEq(redeemBalance, 1e18);
    }

    function test_burnAutoRedeemTokensForDollarsRevertsIfPriceLowerThan1Ether()
        public
    {
        mockTwapFuncs(5e17);
        vm.expectRevert("Price must be above 1 to auto redeem");
        DebtCouponManager(debtCouponManagerAddress)
            .burnAutoRedeemTokensForDollars(100);
    }

    function test_burnAutoRedeemTokensForDollarsIfNotEnoughBalance() public {
        mockTwapFuncs(2e18);
        vm.expectRevert("User doesn't have enough auto redeem pool tokens.");
        DebtCouponManager(debtCouponManagerAddress)
            .burnAutoRedeemTokensForDollars(100);
    }

    function test_burnAutoRedeemTokensForDollarsWorks() public {
        mockTwapFuncs(2e18);
        mockDollarMintingCalcFuncs(1e18);
        address account1 = address(0x123);
        MockAutoRedeem(autoRedeemTokenAddress).mint(account1, 100e18);
        vm.prank(account1);
        uint256 unredeemed = DebtCouponManager(debtCouponManagerAddress)
            .burnAutoRedeemTokensForDollars(10e18);
        assertEq(unredeemed, 10e18 - 1e18);
    }

    function test_redeemCouponsRevertsIfPriceLowerThan1Ether() public {
        mockTwapFuncs(5e17);
        vm.expectRevert("Price must be above 1 to redeem coupons");
        DebtCouponManager(debtCouponManagerAddress).redeemCoupons(
            123123123,
            100
        );
    }

    function test_redeemCouponsRevertsIfCouponExpired() public {
        mockTwapFuncs(2e18);
        vm.roll(10000);
        vm.expectRevert("Coupon has expired");
        DebtCouponManager(debtCouponManagerAddress).redeemCoupons(5555, 100);
    }

    function test_redeemCouponsRevertsIfNotEnoughBalance() public {
        mockTwapFuncs(2e18);
        address account1 = address(0x123);
        uint256 expiryBlockNumber = 123123;
        MockDebtCoupon(debtCouponAddress).mintCoupons(
            account1,
            100,
            expiryBlockNumber
        );
        vm.expectRevert("User not enough coupons");
        vm.prank(account1);
        vm.roll(expiryBlockNumber - 1);
        DebtCouponManager(debtCouponManagerAddress).redeemCoupons(
            expiryBlockNumber,
            200
        );
    }

    function test_redeemCouponsRevertsIfNotEnoughUAD() public {
        mockTwapFuncs(2e18);
        address account1 = address(0x123);
        uint256 expiryBlockNumber = 123123;
        MockDebtCoupon(debtCouponAddress).mintCoupons(
            account1,
            100,
            expiryBlockNumber
        );
        MockAutoRedeem(autoRedeemTokenAddress).mint(
            debtCouponManagerAddress,
            20000e18
        );

        // set excess dollar distributor for debtCouponAddress
        ExcessDollarsDistributor _excessDollarsDistributor = new ExcessDollarsDistributor(
                uADManagerAddress
            );
        helperDeployExcessDollarCalculator(address(_excessDollarsDistributor));
        vm.mockCall(
            address(_excessDollarsDistributor),
            abi.encodeWithSelector(
                ExcessDollarsDistributor.distributeDollars.selector
            ),
            abi.encode()
        );

        vm.prank(account1);
        vm.expectRevert("There aren't enough uAD to redeem currently");
        vm.roll(expiryBlockNumber - 1);
        DebtCouponManager(debtCouponManagerAddress).redeemCoupons(
            expiryBlockNumber,
            99
        );
    }

    function test_redeemCouponsRevertsIfZeroAmountOfUAD() public {
        mockTwapFuncs(2e18);
        mockDollarMintingCalcFuncs(0);
        address account1 = address(0x123);
        uint256 expiryBlockNumber = 123123;
        MockDebtCoupon(debtCouponAddress).mintCoupons(
            account1,
            100,
            expiryBlockNumber
        );
        // MockAutoRedeem(autoRedeemTokenAddress).mint(debtCouponManagerAddress, 20000e18);

        // set excess dollar distributor for debtCouponAddress
        ExcessDollarsDistributor _excessDollarsDistributor = new ExcessDollarsDistributor(
                uADManagerAddress
            );
        helperDeployExcessDollarCalculator(address(_excessDollarsDistributor));
        vm.mockCall(
            address(_excessDollarsDistributor),
            abi.encodeWithSelector(
                ExcessDollarsDistributor.distributeDollars.selector
            ),
            abi.encode()
        );

        vm.prank(account1);
        vm.expectRevert("There aren't any uAD to redeem currently");
        vm.roll(expiryBlockNumber - 1);
        DebtCouponManager(debtCouponManagerAddress).redeemCoupons(
            expiryBlockNumber,
            99
        );
    }

    function test_redeemCouponsWorks() public {
        mockTwapFuncs(2e18);
        mockDollarMintingCalcFuncs(20000e18);
        address account1 = address(0x123);
        uint256 expiryBlockNumber = 123123;
        MockDebtCoupon(debtCouponAddress).mintCoupons(
            account1,
            100,
            expiryBlockNumber
        );
        MockAutoRedeem(autoRedeemTokenAddress).mint(
            debtCouponManagerAddress,
            10000e18
        );

        // set excess dollar distributor for debtCouponAddress
        ExcessDollarsDistributor _excessDollarsDistributor = new ExcessDollarsDistributor(
                uADManagerAddress
            );
        helperDeployExcessDollarCalculator(address(_excessDollarsDistributor));
        vm.mockCall(
            address(_excessDollarsDistributor),
            abi.encodeWithSelector(
                ExcessDollarsDistributor.distributeDollars.selector
            ),
            abi.encode()
        );
        vm.prank(account1);
        vm.roll(expiryBlockNumber - 1);
        uint256 unredeemedCoupons = DebtCouponManager(debtCouponManagerAddress)
            .redeemCoupons(expiryBlockNumber, 99);
        assertEq(unredeemedCoupons, 0);
    }

    function test_mintClaimableDollars() public {
        mockDollarMintingCalcFuncs(50);
        // set excess dollar distributor for debtCouponAddress
        ExcessDollarsDistributor _excessDollarsDistributor = new ExcessDollarsDistributor(
                uADManagerAddress
            );
        helperDeployExcessDollarCalculator(address(_excessDollarsDistributor));
        vm.mockCall(
            address(_excessDollarsDistributor),
            abi.encodeWithSelector(
                ExcessDollarsDistributor.distributeDollars.selector
            ),
            abi.encode()
        );

        uint256 beforeBalance = MockDollarToken(uADAddress).balanceOf(
            debtCouponManagerAddress
        );
        DebtCouponManager(debtCouponManagerAddress).mintClaimableDollars();
        uint256 afterBalance = MockDollarToken(uADAddress).balanceOf(
            debtCouponManagerAddress
        );
        assertEq(afterBalance - beforeBalance, 50);
    }
}
