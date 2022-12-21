// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../../../src/dollar/core/UbiquityDollarManager.sol";
import "../../../src/dollar/core/CreditNFTManager.sol";
import "../../../src/dollar/core/CreditRedemptionCalculator.sol";
import "../../../src/dollar/core/DollarMintCalculator.sol";
import "../../../src/dollar/core/UbiquityCreditToken.sol";
import "../../../src/dollar/core/DollarMintExcess.sol";
import "../../../src/dollar/core/CreditNFT.sol";
import "../../../src/dollar/core/TWAPOracleDollar3pool.sol";

import "../../../src/dollar/mocks/MockDollarToken.sol";
import "../../../src/dollar/mocks/MockCreditNFT.sol";
import "../../../src/dollar/mocks/MockCreditToken.sol";

import "../../helpers/LocalTestHelper.sol";

contract CreditNFTManagerTest is LocalTestHelper {
    address dollarManagerAddress;
    address dollarTokenAddress;
    address creditCalculatorAddress;
    address creditNFTManagerAddress;
    uint256 creditNFTLengthBlocks = 100;
    address twapOracleAddress;
    address creditNFTAddress;
    address governanceTokenAddress;
    address creditTokenAddress;
    address dollarMintCalculatorAddress;

    function setUp() public override {
        super.setUp();
        dollarManagerAddress = address(manager);

        creditNFTManagerAddress = address(
            new CreditNFTManager(dollarManagerAddress, creditNFTLengthBlocks)
        );
        twapOracleAddress =
            UbiquityDollarManager(dollarManagerAddress).twapOracleAddress();
        dollarTokenAddress =
            UbiquityDollarManager(dollarManagerAddress).dollarTokenAddress();
        creditCalculatorAddress = UbiquityDollarManager(dollarManagerAddress)
            .creditCalculatorAddress();
        creditNFTAddress =
            UbiquityDollarManager(dollarManagerAddress).creditNFTAddress();
        governanceTokenAddress =
            UbiquityDollarManager(dollarManagerAddress).governanceTokenAddress();
        creditTokenAddress =
            UbiquityDollarManager(dollarManagerAddress).creditTokenAddress();
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
            creditNFTManagerAddress, _excessDollarsDistributor
        );
    }

    function test_setExpiredCreditNFTConversionRate() public {
        vm.expectRevert("Caller is not a Credit NFT manager");
        CreditNFTManager(creditNFTManagerAddress)
            .setExpiredCreditNFTConversionRate(100);

        vm.prank(admin);
        CreditNFTManager(creditNFTManagerAddress)
            .setExpiredCreditNFTConversionRate(100);
        assertEq(
            CreditNFTManager(creditNFTManagerAddress)
                .expiredCreditNFTConversionRate(),
            100
        );
    }

    function test_setCreditNFTLength() public {
        vm.expectRevert("Caller is not a Credit NFT manager");
        CreditNFTManager(creditNFTManagerAddress).setCreditNFTLength(100);

        vm.prank(admin);
        CreditNFTManager(creditNFTManagerAddress).setCreditNFTLength(100);
        assertEq(
            CreditNFTManager(creditNFTManagerAddress).creditNFTLengthBlocks(),
            100
        );
    }

    function test_exchangeDollarsForCreditNFT() public {
        mockTwapFuncs(2e18);
        vm.expectRevert("Price must be below 1 to mint Credit NFT");
        CreditNFTManager(creditNFTManagerAddress).exchangeDollarsForCreditNFT(
            100
        );

        mockTwapFuncs(5e17);
        address mockSender = address(0x123);
        vm.roll(10000);
        vm.startPrank(mockSender);

        // Mint some dollarTokens to mockSender and then approve all
        MockDollarToken(dollarTokenAddress).mint(mockSender, 10000e18);
        MockDollarToken(dollarTokenAddress).approve(
            creditNFTManagerAddress, 10000e18
        );

        uint256 expiryBlockNumber = CreditNFTManager(creditNFTManagerAddress)
            .exchangeDollarsForCreditNFT(100);
        assertEq(expiryBlockNumber, 10000 + creditNFTLengthBlocks);

        // TODO: We need to add more asserts here for strong sanitation checks
        // like check the difference in creditNFT/dollarToken balance
    }

    function test_exchangeDollarsForCreditRevertsIfPriceHigherThan1Ether()
        public
    {
        mockTwapFuncs(2e18);
        vm.expectRevert("Price must be below 1 to mint Credit");
        CreditNFTManager(creditNFTManagerAddress).exchangeDollarsForCredit(100);
    }

    function test_exchangeDollarsForCreditWorks() public {
        mockTwapFuncs(5e17);
        address mockSender = address(0x123);
        vm.roll(10000);
        vm.startPrank(mockSender);

        // Mint some dollarTokens to mockSender and then approve all
        MockDollarToken(dollarTokenAddress).mint(mockSender, 10000e18);
        MockDollarToken(dollarTokenAddress).approve(
            creditNFTManagerAddress, 10000e18
        );

        mockCreditCalculatorFuncs(10e18);
        uint256 creditAmount = CreditNFTManager(creditNFTManagerAddress)
            .exchangeDollarsForCredit(100);
        assertEq(creditAmount, 10e18);
    }

    function test_burnExpiredCreditNFTForGovernanceRevertsIfNotExpired()
        public
    {
        vm.roll(1000);
        vm.expectRevert("Credit NFT has not expired");
        CreditNFTManager(creditNFTManagerAddress)
            .burnExpiredCreditNFTForGovernance(2000, 1e18);
    }

    function test_burnExpiredCreditNFTForGovernanceRevertsIfNotEnoughBalance()
        public
    {
        address mockMessageSender = address(0x123);
        vm.prank(admin);
        MockCreditNFT(creditNFTAddress).mintCreditNFT(
            mockMessageSender, 100, 500
        );
        vm.roll(1000);
        vm.prank(mockMessageSender);
        vm.expectRevert("User not enough Credit NFT");
        CreditNFTManager(creditNFTManagerAddress)
            .burnExpiredCreditNFTForGovernance(500, 1e18);
    }

    function test_burnExpiredCreditNFTForGovernanceWorks() public {
        address mockMessageSender = address(0x123);
        uint256 expiryBlockNumber = 500;
        vm.startPrank(admin);
        MockCreditNFT(creditNFTAddress).mintCreditNFT(
            mockMessageSender, 2e18, expiryBlockNumber
        );
        UbiquityDollarManager(dollarManagerAddress).grantRole(
            keccak256("UBQ_MINTER_ROLE"), creditNFTManagerAddress
        );
        vm.stopPrank();
        vm.roll(1000);
        vm.prank(mockMessageSender);
        CreditNFTManager(creditNFTManagerAddress)
            .burnExpiredCreditNFTForGovernance(expiryBlockNumber, 1e18);
        uint256 governanceBalance = UbiquityGovernanceToken(
            governanceTokenAddress
        ).balanceOf(mockMessageSender);
        assertEq(governanceBalance, 5e17);
    }

    function test_burnCreditNFTForCreditRevertsIfExpired() public {
        vm.warp(1000);
        vm.expectRevert("Credit NFT has expired");
        CreditNFTManager(creditNFTManagerAddress).burnCreditNFTForCredit(
            500, 1e18
        );
    }

    function test_burnCreditNFTForCreditRevertsIfNotEnoughBalance() public {
        vm.warp(1000);
        vm.expectRevert("User not enough Credit NFT");
        CreditNFTManager(creditNFTManagerAddress).burnCreditNFTForCredit(
            1001, 1e18
        );
    }

    function test_burnCreditNFTForCreditWorks() public {
        address mockMessageSender = address(0x123);
        uint256 expiryBlockNumber = 500;
        vm.startPrank(admin);
        MockCreditNFT(creditNFTAddress).mintCreditNFT(
            mockMessageSender, 2e18, expiryBlockNumber
        );
        UbiquityDollarManager(dollarManagerAddress).grantRole(
            keccak256("GOVERNANCE_TOKEN_MINTER_ROLE"), creditNFTManagerAddress
        );
        vm.stopPrank();
        vm.prank(mockMessageSender);
        vm.warp(expiryBlockNumber - 1);
        CreditNFTManager(creditNFTManagerAddress).burnCreditNFTForCredit(
            expiryBlockNumber, 1e18
        );
        uint256 redeemBalance =
            UbiquityCreditToken(creditTokenAddress).balanceOf(mockMessageSender);
        assertEq(redeemBalance, 1e18);
    }

    function test_burnCreditTokensForDollarsRevertsIfPriceLowerThan1Ether()
        public
    {
        mockTwapFuncs(5e17);
        vm.expectRevert("Price must be above 1");
        CreditNFTManager(creditNFTManagerAddress).burnCreditTokensForDollars(
            100
        );
    }

    function test_burnCreditTokensForDollarsIfNotEnoughBalance() public {
        mockTwapFuncs(2e18);
        vm.expectRevert("User doesn't have enough Credit pool tokens.");
        CreditNFTManager(creditNFTManagerAddress).burnCreditTokensForDollars(
            100
        );
    }

    function test_burnCreditTokensForDollarsWorks() public {
        mockTwapFuncs(2e18);
        mockDollarMintCalcFuncs(1e18);
        address account1 = address(0x123);
        uint256 preBal = dollarToken.balanceOf(account1);
        vm.prank(admin);
        manager.setCreditTokenAddress(creditTokenAddress);
        deal(creditTokenAddress, account1, 100e18);
        deal(dollarTokenAddress, address(creditNFTManager), 10000000e18);
        vm.startPrank(account1);
        MockCreditToken(creditTokenAddress).approve(
            creditNFTManagerAddress, 2 ^ (256 - 1)
        );
        uint256 unredeemed = creditNFTManager.burnCreditTokensForDollars(10e18);
        vm.stopPrank();
        assertEq(unredeemed, 10e18 - 10e18);
        assertEq(preBal + 10e18, dollarToken.balanceOf(account1));
    }

    function test_redeemCreditNFTRevertsIfPriceLowerThan1Ether() public {
        mockTwapFuncs(5e17);
        vm.expectRevert("Price must be above 1 to redeem Credit NFT");
        CreditNFTManager(creditNFTManagerAddress).redeemCreditNFT(
            123123123, 100
        );
    }

    function test_redeemCreditNFTRevertsIfCreditNFTExpired() public {
        mockTwapFuncs(2e18);
        vm.roll(10000);
        vm.expectRevert("Credit NFT has expired");
        CreditNFTManager(creditNFTManagerAddress).redeemCreditNFT(5555, 100);
    }

    function test_redeemCreditNFTRevertsIfNotEnoughBalance() public {
        mockTwapFuncs(2e18);
        address account1 = address(0x123);
        uint256 expiryBlockNumber = 123123;
        MockCreditNFT(creditNFTAddress).mintCreditNFT(
            account1, 100, expiryBlockNumber
        );
        vm.expectRevert("User not enough Credit NFT");
        vm.prank(account1);
        vm.roll(expiryBlockNumber - 1);
        CreditNFTManager(creditNFTManagerAddress).redeemCreditNFT(
            expiryBlockNumber, 200
        );
    }

    function test_redeemCreditNFTRevertsIfNotEnoughDollars() public {
        mockTwapFuncs(2e18);
        address account1 = address(0x123);
        uint256 expiryBlockNumber = 123123;
        MockCreditNFT(creditNFTAddress).mintCreditNFT(
            account1, 100, expiryBlockNumber
        );
        MockCreditToken(creditTokenAddress).mint(
            creditNFTManagerAddress, 20000e18
        );

        // set excess dollar distributor for creditNFTAddress
        DollarMintExcess _excessDollarsDistributor = new DollarMintExcess(
            dollarManagerAddress
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
        CreditNFTManager(creditNFTManagerAddress).redeemCreditNFT(
            expiryBlockNumber, 99
        );
    }

    function test_redeemCreditNFTRevertsIfZeroAmountOfDollars() public {
        mockTwapFuncs(2e18);
        mockDollarMintCalcFuncs(0);
        address account1 = address(0x123);
        uint256 expiryBlockNumber = 123123;
        MockCreditNFT(creditNFTAddress).mintCreditNFT(
            account1, 100, expiryBlockNumber
        );
        // MockAutoRedeem(creditTokenAddress).mint(creditNFTManagerAddress, 20000e18);

        // set excess dollar distributor for creditNFTAddress
        DollarMintExcess _excessDollarsDistributor = new DollarMintExcess(
            dollarManagerAddress
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
        CreditNFTManager(creditNFTManagerAddress).redeemCreditNFT(
            expiryBlockNumber, 99
        );
    }

    function test_redeemCreditNFTWorks() public {
        mockTwapFuncs(2e18);
        mockDollarMintCalcFuncs(20000e18);
        address account1 = address(0x123);
        uint256 expiryBlockNumber = 123123;
        MockCreditNFT(creditNFTAddress).mintCreditNFT(
            account1, 100, expiryBlockNumber
        );
        MockCreditToken(creditTokenAddress).mint(
            creditNFTManagerAddress, 10000e18
        );

        // set excess dollar distributor for debtCouponAddress
        DollarMintExcess _excessDollarsDistributor = new DollarMintExcess(
            dollarManagerAddress
        );
        helperDeployExcessDollarCalculator(address(_excessDollarsDistributor));
        vm.mockCall(
            address(_excessDollarsDistributor),
            abi.encodeWithSelector(DollarMintExcess.distributeDollars.selector),
            abi.encode()
        );
        vm.prank(account1);
        vm.roll(expiryBlockNumber - 1);
        uint256 unredeemedCreditNFT = CreditNFTManager(creditNFTManagerAddress)
            .redeemCreditNFT(expiryBlockNumber, 99);
        assertEq(unredeemedCreditNFT, 0);
    }

    function test_mintClaimableDollars() public {
        mockDollarMintCalcFuncs(50);
        // set excess dollar distributor for creditNFTAddress
        DollarMintExcess _excessDollarsDistributor = new DollarMintExcess(
            dollarManagerAddress
        );
        helperDeployExcessDollarCalculator(address(_excessDollarsDistributor));
        vm.mockCall(
            address(_excessDollarsDistributor),
            abi.encodeWithSelector(DollarMintExcess.distributeDollars.selector),
            abi.encode()
        );

        uint256 beforeBalance = MockDollarToken(dollarTokenAddress).balanceOf(
            creditNFTManagerAddress
        );
        CreditNFTManager(creditNFTManagerAddress).mintClaimableDollars();
        uint256 afterBalance = MockDollarToken(dollarTokenAddress).balanceOf(
            creditNFTManagerAddress
        );
        assertEq(afterBalance - beforeBalance, 50);
    }
}
