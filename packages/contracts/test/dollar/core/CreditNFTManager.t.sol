// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {UbiquityDollarManager} from
    "../../../src/dollar/core/UbiquityDollarManager.sol";
import {CreditNFTManager} from "../../../src/dollar/core/CreditNFTManager.sol";
import {CreditRedemptionCalculator} from
    "../../../src/dollar/core/CreditRedemptionCalculator.sol";
import {DollarMintCalculator} from
    "../../../src/dollar/core/DollarMintCalculator.sol";
import {UbiquityCreditToken} from "../../../src/dollar/core/UbiquityCreditToken.sol";
import {DollarMintExcess} from
    "../../../src/dollar/core/DollarMintExcess.sol";
import {CreditNFT} from "../../../src/dollar/core/CreditNFT.sol";
import {TWAPOracleDollar3pool} from "../../../src/dollar/core/TWAPOracleDollar3pool.sol";

import {MockDollarToken} from "../../../src/dollar/mocks/MockDollarToken.sol";
import {MockCreditNFT} from "../../../src/dollar/mocks/MockCreditNFT.sol";
import {MockCreditToken} from "../../../src/dollar/mocks/MockCreditToken.sol";

import "../../helpers/LocalTestHelper.sol";

contract CreditNFTManagerTest is LocalTestHelper {
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
        uADManagerAddress = helpers_deployUbiquityDollarManager();

        debtCouponManagerAddress = address(
            new CreditNFTManager(uADManagerAddress, couponLengthBlocks)
        );
        twapOracleAddress = UbiquityDollarManager(uADManagerAddress)
            .twapOracleAddress();
        uADAddress = UbiquityDollarManager(uADManagerAddress)
            .dollarTokenAddress();
        uARDollarCalculatorAddress = UbiquityDollarManager(
            uADManagerAddress
        ).uarCalculatorAddress();
        debtCouponAddress = UbiquityDollarManager(uADManagerAddress)
            .debtCouponAddress();
        uGovAddress = UbiquityDollarManager(uADManagerAddress)
            .governanceTokenAddress();
        autoRedeemTokenAddress = UbiquityDollarManager(
            uADManagerAddress
        ).autoRedeemTokenAddress();
        dollarMintingCalculatorAddress = UbiquityDollarManager(
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
                CreditRedemptionCalculator.getUARAmount.selector
            ),
            abi.encode(_uarAmount)
        );
    }

    function mockDollarMintingCalcFuncs(uint256 _dollarsToMint) public {
        vm.mockCall(
            dollarMintingCalculatorAddress,
            abi.encodeWithSelector(
                DollarMintCalculator.getDollarsToMint.selector
            ),
            abi.encode(_dollarsToMint)
        );
    }

    function helperDeployExcessDollarCalculator(
        address _excessDollarsDistributor
    ) public {
        vm.prank(admin);
        UbiquityDollarManager(uADManagerAddress)
            .setExcessDollarsDistributor(
            debtCouponManagerAddress, _excessDollarsDistributor
        );
    }

    function test_setExpiredCouponConversionRate() public {
        vm.expectRevert("Caller is not a coupon manager");
        CreditNFTManager(debtCouponManagerAddress)
            .setExpiredCouponConversionRate(100);

        vm.prank(admin);
        CreditNFTManager(debtCouponManagerAddress)
            .setExpiredCouponConversionRate(100);
        assertEq(
            CreditNFTManager(debtCouponManagerAddress)
                .expiredCouponConversionRate(),
            100
        );
    }

    function test_setCouponLength() public {
        vm.expectRevert("Caller is not a coupon manager");
        CreditNFTManager(debtCouponManagerAddress).setCouponLength(100);

        vm.prank(admin);
        CreditNFTManager(debtCouponManagerAddress).setCouponLength(100);
        assertEq(
            CreditNFTManager(debtCouponManagerAddress).couponLengthBlocks(),
            100
        );
    }

    function test_exchangeDollarsForDebtCoupons() public {
        mockTwapFuncs(2e18);
        vm.expectRevert("Price must be below 1 to mint coupons");
        CreditNFTManager(debtCouponManagerAddress)
            .exchangeDollarsForDebtCoupons(100);

        mockTwapFuncs(5e17);
        address mockSender = address(0x123);
        vm.roll(10000);
        vm.startPrank(mockSender);

        // Mint some dollarTokens to mockSender and then approve all
        MockDollarToken(uADAddress).mint(mockSender, 10000e18);
        MockDollarToken(uADAddress).approve(debtCouponManagerAddress, 10000e18);

        uint256 expiryBlockNumber = CreditNFTManager(debtCouponManagerAddress)
            .exchangeDollarsForDebtCoupons(100);
        assertEq(expiryBlockNumber, 10000 + couponLengthBlocks);

        // TODO: We need to add more asserts here for strong sanitation checks
        // like check the difference in debtCoupon/dollarToken balance
    }

    function test_exchangeDollarsForUARRevertsIfPriceHigherThan1Ether()
        public
    {
        mockTwapFuncs(2e18);
        vm.expectRevert("Price must be below 1 to mint uAR");
        CreditNFTManager(debtCouponManagerAddress).exchangeDollarsForUAR(100);
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
        uint256 uARAmount = CreditNFTManager(debtCouponManagerAddress)
            .exchangeDollarsForUAR(100);
        assertEq(uARAmount, 10e18);
    }

    function test_burnExpiredCouponsForUGOVRevertsIfNotExpired() public {
        vm.roll(1000);
        vm.expectRevert("Coupon has not expired");
        CreditNFTManager(debtCouponManagerAddress).burnExpiredCouponsForUGOV(
            2000, 1e18
        );
    }

    function test_burnExpiredCouponsForUGOVRevertsIfNotEnoughBalance() public {
        address mockMessageSender = address(0x123);
        vm.prank(admin);
        MockCreditNFT(debtCouponAddress).mintCoupons(
            mockMessageSender, 100, 500
        );
        vm.roll(1000);
        vm.prank(mockMessageSender);
        vm.expectRevert("User not enough coupons");
        CreditNFTManager(debtCouponManagerAddress).burnExpiredCouponsForUGOV(
            500, 1e18
        );
    }

    function test_burnExpiredCouponsForUGOVWorks() public {
        address mockMessageSender = address(0x123);
        uint256 expiryBlockNumber = 500;
        vm.startPrank(admin);
        MockCreditNFT(debtCouponAddress).mintCoupons(
            mockMessageSender, 2e18, expiryBlockNumber
        );
        UbiquityDollarManager(uADManagerAddress).grantRole(
            keccak256("UBQ_MINTER_ROLE"), debtCouponManagerAddress
        );
        vm.stopPrank();
        vm.roll(1000);
        vm.prank(mockMessageSender);
        CreditNFTManager(debtCouponManagerAddress).burnExpiredCouponsForUGOV(
            expiryBlockNumber, 1e18
        );
        uint256 uGovBalance =
            UbiquityGovernanceToken(uGovAddress).balanceOf(mockMessageSender);
        assertEq(uGovBalance, 5e17);
    }

    function test_burnCouponsForAutoRedemptionRevertsIfExpired() public {
        vm.warp(1000);
        vm.expectRevert("Coupon has expired");
        CreditNFTManager(debtCouponManagerAddress).burnCouponsForAutoRedemption(
            500, 1e18
        );
    }

    function test_burnCouponsForAutoRedemptionRevertsIfNotEnoughBalance()
        public
    {
        vm.warp(1000);
        vm.expectRevert("User not enough coupons");
        CreditNFTManager(debtCouponManagerAddress).burnCouponsForAutoRedemption(
            1001, 1e18
        );
    }

    function test_burnCouponsForAutoRedemptionWorks() public {
        address mockMessageSender = address(0x123);
        uint256 expiryBlockNumber = 500;
        vm.startPrank(admin);
        MockCreditNFT(debtCouponAddress).mintCoupons(
            mockMessageSender, 2e18, expiryBlockNumber
        );
        UbiquityDollarManager(uADManagerAddress).grantRole(
            keccak256("UBQ_MINTER_ROLE"), debtCouponManagerAddress
        );
        vm.stopPrank();
        vm.prank(mockMessageSender);
        vm.warp(expiryBlockNumber - 1);
        CreditNFTManager(debtCouponManagerAddress).burnCouponsForAutoRedemption(
            expiryBlockNumber, 1e18
        );
        uint256 redeemBalance = UbiquityCreditToken(autoRedeemTokenAddress)
            .balanceOf(mockMessageSender);
        assertEq(redeemBalance, 1e18);
    }

    function test_burnAutoRedeemTokensForDollarsRevertsIfPriceLowerThan1Ether()
        public
    {
        mockTwapFuncs(5e17);
        vm.expectRevert("Price must be above 1 to auto redeem");
        CreditNFTManager(debtCouponManagerAddress)
            .burnAutoRedeemTokensForDollars(100);
    }

    function test_burnAutoRedeemTokensForDollarsIfNotEnoughBalance() public {
        mockTwapFuncs(2e18);
        vm.expectRevert("User doesn't have enough auto redeem pool tokens.");
        CreditNFTManager(debtCouponManagerAddress)
            .burnAutoRedeemTokensForDollars(100);
    }

    function test_burnAutoRedeemTokensForDollarsWorks() public {
        mockTwapFuncs(2e18);
        mockDollarMintingCalcFuncs(1e18);
        address account1 = address(0x123);
        MockCreditToken(autoRedeemTokenAddress).mint(account1, 100e18);
        vm.prank(account1);
        uint256 unredeemed = CreditNFTManager(debtCouponManagerAddress)
            .burnAutoRedeemTokensForDollars(10e18);
        assertEq(unredeemed, 10e18 - 1e18);
    }

    function test_redeemCouponsRevertsIfPriceLowerThan1Ether() public {
        mockTwapFuncs(5e17);
        vm.expectRevert("Price must be above 1 to redeem coupons");
        CreditNFTManager(debtCouponManagerAddress).redeemCoupons(
            123123123, 100
        );
    }

    function test_redeemCouponsRevertsIfCouponExpired() public {
        mockTwapFuncs(2e18);
        vm.roll(10000);
        vm.expectRevert("Coupon has expired");
        CreditNFTManager(debtCouponManagerAddress).redeemCoupons(5555, 100);
    }

    function test_redeemCouponsRevertsIfNotEnoughBalance() public {
        mockTwapFuncs(2e18);
        address account1 = address(0x123);
        uint256 expiryBlockNumber = 123123;
        MockCreditNFT(debtCouponAddress).mintCoupons(
            account1, 100, expiryBlockNumber
        );
        vm.expectRevert("User not enough coupons");
        vm.prank(account1);
        vm.roll(expiryBlockNumber - 1);
        CreditNFTManager(debtCouponManagerAddress).redeemCoupons(
            expiryBlockNumber, 200
        );
    }

    function test_redeemCouponsRevertsIfNotEnoughUAD() public {
        mockTwapFuncs(2e18);
        address account1 = address(0x123);
        uint256 expiryBlockNumber = 123123;
        MockCreditNFT(debtCouponAddress).mintCoupons(
            account1, 100, expiryBlockNumber
        );
        MockCreditToken(autoRedeemTokenAddress).mint(
            debtCouponManagerAddress, 20000e18
        );

        // set excess dollar distributor for debtCouponAddress
        DollarMintExcess _excessDollarsDistributor =
            new DollarMintExcess(uADManagerAddress);
        helperDeployExcessDollarCalculator(address(_excessDollarsDistributor));
        vm.mockCall(
            address(_excessDollarsDistributor),
            abi.encodeWithSelector(
                DollarMintExcess.distributeDollars.selector
            ),
            abi.encode()
        );

        vm.prank(account1);
        vm.expectRevert("There aren't enough uAD to redeem currently");
        vm.roll(expiryBlockNumber - 1);
        CreditNFTManager(debtCouponManagerAddress).redeemCoupons(
            expiryBlockNumber, 99
        );
    }

    function test_redeemCouponsRevertsIfZeroAmountOfUAD() public {
        mockTwapFuncs(2e18);
        mockDollarMintingCalcFuncs(0);
        address account1 = address(0x123);
        uint256 expiryBlockNumber = 123123;
        MockCreditNFT(debtCouponAddress).mintCoupons(
            account1, 100, expiryBlockNumber
        );
        // MockAutoRedeem(autoRedeemTokenAddress).mint(debtCouponManagerAddress, 20000e18);

        // set excess dollar distributor for debtCouponAddress
        DollarMintExcess _excessDollarsDistributor =
            new DollarMintExcess(uADManagerAddress);
        helperDeployExcessDollarCalculator(address(_excessDollarsDistributor));
        vm.mockCall(
            address(_excessDollarsDistributor),
            abi.encodeWithSelector(
                DollarMintExcess.distributeDollars.selector
            ),
            abi.encode()
        );

        vm.prank(account1);
        vm.expectRevert("There aren't any uAD to redeem currently");
        vm.roll(expiryBlockNumber - 1);
        CreditNFTManager(debtCouponManagerAddress).redeemCoupons(
            expiryBlockNumber, 99
        );
    }

    function test_redeemCouponsWorks() public {
        mockTwapFuncs(2e18);
        mockDollarMintingCalcFuncs(20000e18);
        address account1 = address(0x123);
        uint256 expiryBlockNumber = 123123;
        MockCreditNFT(debtCouponAddress).mintCoupons(
            account1, 100, expiryBlockNumber
        );
        MockCreditToken(autoRedeemTokenAddress).mint(
            debtCouponManagerAddress, 10000e18
        );

        // set excess dollar distributor for debtCouponAddress
        DollarMintExcess _excessDollarsDistributor =
            new DollarMintExcess(uADManagerAddress);
        helperDeployExcessDollarCalculator(address(_excessDollarsDistributor));
        vm.mockCall(
            address(_excessDollarsDistributor),
            abi.encodeWithSelector(
                DollarMintExcess.distributeDollars.selector
            ),
            abi.encode()
        );
        vm.prank(account1);
        vm.roll(expiryBlockNumber - 1);
        uint256 unredeemedCoupons = CreditNFTManager(debtCouponManagerAddress)
            .redeemCoupons(expiryBlockNumber, 99);
        assertEq(unredeemedCoupons, 0);
    }

    function test_mintClaimableDollars() public {
        mockDollarMintingCalcFuncs(50);
        // set excess dollar distributor for debtCouponAddress
        DollarMintExcess _excessDollarsDistributor =
            new DollarMintExcess(uADManagerAddress);
        helperDeployExcessDollarCalculator(address(_excessDollarsDistributor));
        vm.mockCall(
            address(_excessDollarsDistributor),
            abi.encodeWithSelector(
                DollarMintExcess.distributeDollars.selector
            ),
            abi.encode()
        );

        uint256 beforeBalance =
            MockDollarToken(uADAddress).balanceOf(debtCouponManagerAddress);
        CreditNFTManager(debtCouponManagerAddress).mintClaimableDollars();
        uint256 afterBalance =
            MockDollarToken(uADAddress).balanceOf(debtCouponManagerAddress);
        assertEq(afterBalance - beforeBalance, 50);
    }
}
