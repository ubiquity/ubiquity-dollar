// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {UbiquityDollarManager} from "../../../src/dollar/core/UbiquityDollarManager.sol";
import {CreditNftManager} from "../../../src/dollar/core/CreditNftManager.sol";
import {CreditRedemptionCalculator} from "../../../src/dollar/core/CreditRedemptionCalculator.sol";
import {DollarMintCalculator} from "../../../src/dollar/core/DollarMintCalculator.sol";
import {UbiquityCreditToken} from "../../../src/dollar/core/UbiquityCreditToken.sol";
import {DollarMintExcess} from "../../../src/dollar/core/DollarMintExcess.sol";
import {CreditNft} from "../../../src/dollar/core/CreditNft.sol";
import {TWAPOracleDollar3pool} from "../../../src/dollar/core/TWAPOracleDollar3pool.sol";

import "../../../src/dollar/mocks/MockDollarToken.sol";
import "../../../src/dollar/mocks/MockCreditNft.sol";
import "../../../src/dollar/mocks/MockCreditToken.sol";

import "../../helpers/LocalTestHelper.sol";

contract CreditNftManagerTest is LocalTestHelper {
    address dollarManagerAddress;
    address dollarTokenAddress;
    address creditCalculatorAddress;
    address creditNftManagerAddress;
    uint256 creditNftLengthBlocks = 100;
    address twapOracleAddress;
    address creditNftAddress;
    address governanceTokenAddress;
    address creditTokenAddress;
    address dollarMintCalculatorAddress;

    function setUp() public override {
        super.setUp();
        dollarManagerAddress = address(manager);

        creditNftManagerAddress = address(
            new CreditNftManager(manager, creditNftLengthBlocks)
        );
        twapOracleAddress = manager.twapOracleAddress();
        dollarTokenAddress = manager.dollarTokenAddress();
        creditCalculatorAddress = UbiquityDollarManager(dollarManagerAddress)
            .creditCalculatorAddress();
        creditNftAddress = UbiquityDollarManager(dollarManagerAddress)
            .creditNftAddress();
        governanceTokenAddress = UbiquityDollarManager(dollarManagerAddress)
            .governanceTokenAddress();
        creditTokenAddress = UbiquityDollarManager(dollarManagerAddress)
            .creditTokenAddress();
        dollarMintCalculatorAddress = UbiquityDollarManager(
            dollarManagerAddress
        ).dollarMintCalculatorAddress();
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

    function mockCreditCalculatorFuncs(uint256 _creditAmount) public {
        vm.mockCall(
            creditCalculatorAddress,
            abi.encodeWithSelector(
                CreditRedemptionCalculator.getCreditAmount.selector
            ),
            abi.encode(_creditAmount)
        );
    }

    function mockDollarMintCalcFuncs(uint256 _dollarsToMint) public {
        vm.mockCall(
            dollarMintCalculatorAddress,
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
        UbiquityDollarManager(dollarManagerAddress).setExcessDollarsDistributor(
                creditNftManagerAddress,
                _excessDollarsDistributor
            );
    }

    function testSetExpiredCreditNftConversionRateShouldRevertIfCallerIsNotCreditNftManager()
        public
    {
        vm.expectRevert("Caller is not a Credit Nft manager");
        CreditNftManager(creditNftManagerAddress)
            .setExpiredCreditNftConversionRate(100);

        vm.prank(admin);
        CreditNftManager(creditNftManagerAddress)
            .setExpiredCreditNftConversionRate(100);
        assertEq(
            CreditNftManager(creditNftManagerAddress)
                .expiredCreditNftConversionRate(),
            100
        );
    }

    function testSetCreditNftLength_ShouldRevert_IfCallerIsNotCreditNftManager()
        public
    {
        vm.expectRevert("Caller is not a Credit Nft manager");
        CreditNftManager(creditNftManagerAddress).setCreditNftLength(100);

        vm.prank(admin);
        CreditNftManager(creditNftManagerAddress).setCreditNftLength(100);
        assertEq(
            CreditNftManager(creditNftManagerAddress).creditNftLengthBlocks(),
            100
        );
    }

    function testExchangeDollarsForCreditNft_ShouldBeSuccessful_WhenTestedWithCorrectPrice()
        public
    {
        mockTwapFuncs(2e18);
        vm.expectRevert("Price must be below 1 to mint Credit Nft");
        CreditNftManager(creditNftManagerAddress).exchangeDollarsForCreditNft(
            100
        );

        mockTwapFuncs(5e17);
        address mockSender = address(0x123);
        vm.roll(10000);
        vm.startPrank(mockSender);

        // Mint some dollarTokens to mockSender and then approve all
        MockDollarToken(dollarTokenAddress).mint(mockSender, 10000e18);
        MockDollarToken(dollarTokenAddress).approve(
            creditNftManagerAddress,
            10000e18
        );

        uint256 expiryBlockNumber = CreditNftManager(creditNftManagerAddress)
            .exchangeDollarsForCreditNft(100);
        assertEq(expiryBlockNumber, 10000 + creditNftLengthBlocks);

        // TODO: We need to add more asserts here for strong sanitation checks
        // like check the difference in creditNft/dollarToken balance
    }

    function testExchangeDollarsForCredit_ShouldRevert_IfPriceHigherThan1Ether()
        public
    {
        mockTwapFuncs(2e18);
        vm.expectRevert("Price must be below 1 to mint Credit");
        CreditNftManager(creditNftManagerAddress).exchangeDollarsForCredit(100);
    }

    function testExchangeDollarsForCredit_ShouldBeSuccessful() public {
        mockTwapFuncs(5e17);
        address mockSender = address(0x123);
        vm.roll(10000);
        vm.startPrank(mockSender);

        // Mint some dollarTokens to mockSender and then approve all
        MockDollarToken(dollarTokenAddress).mint(mockSender, 10000e18);
        MockDollarToken(dollarTokenAddress).approve(
            creditNftManagerAddress,
            10000e18
        );

        mockCreditCalculatorFuncs(10e18);
        uint256 creditAmount = CreditNftManager(creditNftManagerAddress)
            .exchangeDollarsForCredit(100);
        assertEq(creditAmount, 10e18);
    }

    function testBurnExpiredCreditNftForGovernance_ShouldRevert_IfNotExpired()
        public
    {
        vm.roll(1000);
        vm.expectRevert("Credit Nft has not expired");
        CreditNftManager(creditNftManagerAddress)
            .burnExpiredCreditNftForGovernance(2000, 1e18);
    }

    function testBurnExpiredCreditNftForGovernance_ShouldRevert_IfNotEnoughCreditNft()
        public
    {
        address mockMessageSender = address(0x123);
        vm.prank(admin);
        MockCreditNft(creditNftAddress).mintCreditNft(
            mockMessageSender,
            100,
            500
        );
        vm.roll(1000);
        vm.prank(mockMessageSender);
        vm.expectRevert("User not enough Credit Nft");
        CreditNftManager(creditNftManagerAddress)
            .burnExpiredCreditNftForGovernance(500, 1e18);
    }

    function testBurnExpiredCreditNftForGovernance_ShouldWork() public {
        address mockMessageSender = address(0x123);
        uint256 expiryBlockNumber = 500;
        vm.startPrank(admin);
        MockCreditNft(creditNftAddress).mintCreditNft(
            mockMessageSender,
            2e18,
            expiryBlockNumber
        );
        UbiquityDollarManager(dollarManagerAddress).grantRole(
            keccak256("GOVERNANCE_TOKEN_MINTER_ROLE"),
            creditNftManagerAddress
        );
        vm.stopPrank();
        vm.roll(1000);
        vm.prank(mockMessageSender);
        CreditNftManager(creditNftManagerAddress)
            .burnExpiredCreditNftForGovernance(expiryBlockNumber, 1e18);
        uint256 governanceBalance = UbiquityGovernanceToken(
            governanceTokenAddress
        ).balanceOf(mockMessageSender);
        assertEq(governanceBalance, 5e17);
    }

    function testBurnCreditNftForCredit_ShouldRevert_WhenCreditNftExpired()
        public
    {
        vm.warp(1000);
        vm.expectRevert("Credit Nft has expired");
        CreditNftManager(creditNftManagerAddress).burnCreditNftForCredit(
            500,
            1e18
        );
    }

    function testBurnCreditNftForCredit_ShouldRevert_WhenNotEnoughCreditNft()
        public
    {
        vm.warp(1000);
        vm.expectRevert("User not enough Credit Nft");
        CreditNftManager(creditNftManagerAddress).burnCreditNftForCredit(
            1001,
            1e18
        );
    }

    function testBurnCreditNftForCredit_ShouldWork() public {
        address mockMessageSender = address(0x123);
        uint256 expiryBlockNumber = 500;
        vm.startPrank(admin);
        MockCreditNft(creditNftAddress).mintCreditNft(
            mockMessageSender,
            2e18,
            expiryBlockNumber
        );
        UbiquityDollarManager(dollarManagerAddress).grantRole(
            keccak256("GOVERNANCE_TOKEN_MINTER_ROLE"),
            creditNftManagerAddress
        );
        vm.stopPrank();
        vm.prank(mockMessageSender);
        vm.warp(expiryBlockNumber - 1);
        CreditNftManager(creditNftManagerAddress).burnCreditNftForCredit(
            expiryBlockNumber,
            1e18
        );
        uint256 redeemBalance = UbiquityCreditToken(creditTokenAddress)
            .balanceOf(mockMessageSender);
        assertEq(redeemBalance, 1e18);
    }

    function testBurnCreditTokensForDollars_ShouldRevert_IfPriceLowerThan1Ether()
        public
    {
        mockTwapFuncs(5e17);
        vm.expectRevert("Price must be above 1");
        CreditNftManager(creditNftManagerAddress).burnCreditTokensForDollars(
            100
        );
    }

    function testBurnCreditTokensForDollars_ShouldRevertIfUserDoesNotHaveEnoughCreditPoolTokens()
        public
    {
        mockTwapFuncs(2e18);
        vm.expectRevert("User doesn't have enough Credit pool tokens.");
        CreditNftManager(creditNftManagerAddress).burnCreditTokensForDollars(
            100
        );
    }

    function testBurnCreditTokensForDollars_ShouldWork() public {
        mockTwapFuncs(2e18);
        mockDollarMintCalcFuncs(1e18);
        address account1 = address(0x123);
        uint256 preBal = dollarToken.balanceOf(account1);
        vm.prank(admin);
        manager.setCreditTokenAddress(creditTokenAddress);
        deal(creditTokenAddress, account1, 100e18);
        deal(dollarTokenAddress, address(creditNftManager), 10000000e18);
        vm.startPrank(account1);
        MockCreditToken(creditTokenAddress).approve(
            creditNftManagerAddress,
            2 ^ (256 - 1)
        );
        uint256 unredeemed = creditNftManager.burnCreditTokensForDollars(10e18);
        vm.stopPrank();
        assertEq(unredeemed, 10e18 - 10e18);
        assertEq(preBal + 10e18, dollarToken.balanceOf(account1));
    }

    function testRedeemCreditNft_ShouldRevert_IfPriceLowerThan1Ether() public {
        mockTwapFuncs(5e17);
        vm.expectRevert("Price must be above 1 to redeem Credit Nft");
        CreditNftManager(creditNftManagerAddress).redeemCreditNft(
            123123123,
            100
        );
    }

    function testRedeemCreditNft_ShouldRevert_IfCreditNftExpired() public {
        mockTwapFuncs(2e18);
        vm.roll(10000);
        vm.expectRevert("Credit Nft has expired");
        CreditNftManager(creditNftManagerAddress).redeemCreditNft(5555, 100);
    }

    function testRedeemCreditNft_ShouldRevert_IfNotEnoughBalance() public {
        mockTwapFuncs(2e18);
        address account1 = address(0x123);
        uint256 expiryBlockNumber = 123123;
        MockCreditNft(creditNftAddress).mintCreditNft(
            account1,
            100,
            expiryBlockNumber
        );
        vm.expectRevert("User not enough Credit Nft");
        vm.prank(account1);
        vm.roll(expiryBlockNumber - 1);
        CreditNftManager(creditNftManagerAddress).redeemCreditNft(
            expiryBlockNumber,
            200
        );
    }

    function testRedeemCreditNft_ShouldRevert_WhenNotEnoughDollars() public {
        mockTwapFuncs(2e18);
        address account1 = address(0x123);
        uint256 expiryBlockNumber = 123123;
        MockCreditNft(creditNftAddress).mintCreditNft(
            account1,
            100,
            expiryBlockNumber
        );
        MockCreditToken(creditTokenAddress).mint(
            creditNftManagerAddress,
            20000e18
        );

        // set excess dollar distributor for creditNftAddress
        DollarMintExcess _excessDollarsDistributor = new DollarMintExcess(
            manager
        );
        helperDeployExcessDollarCalculator(address(_excessDollarsDistributor));
        vm.mockCall(
            address(_excessDollarsDistributor),
            abi.encodeWithSelector(DollarMintExcess.distributeDollars.selector),
            abi.encode()
        );

        vm.prank(account1);
        vm.expectRevert("There aren't enough Dollar to redeem currently");
        vm.roll(expiryBlockNumber - 1);
        CreditNftManager(creditNftManagerAddress).redeemCreditNft(
            expiryBlockNumber,
            99
        );
    }

    function testRedeemCreditNft_ShouldRevert_WhenZeroAmountOfDollars() public {
        mockTwapFuncs(2e18);
        mockDollarMintCalcFuncs(0);
        address account1 = address(0x123);
        uint256 expiryBlockNumber = 123123;
        MockCreditNft(creditNftAddress).mintCreditNft(
            account1,
            100,
            expiryBlockNumber
        );
        // MockAutoRedeem(creditTokenAddress).mint(creditNftManagerAddress, 20000e18);

        // set excess dollar distributor for creditNftAddress
        DollarMintExcess _excessDollarsDistributor = new DollarMintExcess(
            manager
        );
        helperDeployExcessDollarCalculator(address(_excessDollarsDistributor));
        vm.mockCall(
            address(_excessDollarsDistributor),
            abi.encodeWithSelector(DollarMintExcess.distributeDollars.selector),
            abi.encode()
        );

        vm.prank(account1);
        vm.expectRevert("There aren't any Dollar to redeem currently");
        vm.roll(expiryBlockNumber - 1);
        CreditNftManager(creditNftManagerAddress).redeemCreditNft(
            expiryBlockNumber,
            99
        );
    }

    function testRedeemCreditNft_ShouldWork() public {
        mockTwapFuncs(2e18);
        mockDollarMintCalcFuncs(20000e18);
        address account1 = address(0x123);
        uint256 expiryBlockNumber = 123123;
        MockCreditNft(creditNftAddress).mintCreditNft(
            account1,
            100,
            expiryBlockNumber
        );
        MockCreditToken(creditTokenAddress).mint(
            creditNftManagerAddress,
            10000e18
        );

        // set excess dollar distributor for debtCouponAddress
        DollarMintExcess _excessDollarsDistributor = new DollarMintExcess(
            manager
        );
        helperDeployExcessDollarCalculator(address(_excessDollarsDistributor));
        vm.mockCall(
            address(_excessDollarsDistributor),
            abi.encodeWithSelector(DollarMintExcess.distributeDollars.selector),
            abi.encode()
        );
        vm.prank(account1);
        vm.roll(expiryBlockNumber - 1);
        uint256 unredeemedCreditNft = CreditNftManager(creditNftManagerAddress)
            .redeemCreditNft(expiryBlockNumber, 99);
        assertEq(unredeemedCreditNft, 0);
    }

    function testMintClaimableDollars_ShouldWork() public {
        mockDollarMintCalcFuncs(50);
        // set excess dollar distributor for creditNftAddress
        DollarMintExcess _excessDollarsDistributor = new DollarMintExcess(
            manager
        );
        helperDeployExcessDollarCalculator(address(_excessDollarsDistributor));
        vm.mockCall(
            address(_excessDollarsDistributor),
            abi.encodeWithSelector(DollarMintExcess.distributeDollars.selector),
            abi.encode()
        );

        uint256 beforeBalance = MockDollarToken(dollarTokenAddress).balanceOf(
            creditNftManagerAddress
        );
        CreditNftManager(creditNftManagerAddress).mintClaimableDollars();
        uint256 afterBalance = MockDollarToken(dollarTokenAddress).balanceOf(
            creditNftManagerAddress
        );
        assertEq(afterBalance - beforeBalance, 50);
    }
}
