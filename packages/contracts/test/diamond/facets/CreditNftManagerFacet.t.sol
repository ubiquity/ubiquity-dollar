// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../DiamondTestSetup.sol";
import {CreditNftManagerFacet} from "../../../src/dollar/facets/CreditNftManagerFacet.sol";
import {CreditRedemptionCalculatorFacet} from "../../../src/dollar/facets/CreditRedemptionCalculatorFacet.sol";
import {DollarMintCalculatorFacet} from "../../../src/dollar/facets/DollarMintCalculatorFacet.sol";
import {DollarMintExcessFacet} from "../../../src/dollar/facets/DollarMintExcessFacet.sol";
import {TWAPOracleDollar3poolFacet} from "../../../src/dollar/facets/TWAPOracleDollar3poolFacet.sol";
import "../../../src/dollar/libraries/Constants.sol";
import {IERC20Ubiquity} from "../../../src/dollar/interfaces/IERC20Ubiquity.sol";
import {MockDollarToken} from "../../../src/dollar/mocks/MockDollarToken.sol";
import {MockCreditNft} from "../../../src/dollar/mocks/MockCreditNft.sol";
import {MockCreditToken} from "../../../src/dollar/mocks/MockCreditToken.sol";
import {UbiquityCreditToken} from "../../../src/dollar/core/UbiquityCreditToken.sol";

contract CreditNftManagerFacetTest is DiamondSetup {
    MockCreditNft _creditNft;
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

    function setUp() public virtual override {
        super.setUp();
        vm.prank(admin);
        IDollar.mint(admin, 10000e18);
        uint256 admSupply = IDollar.balanceOf(admin);
        assertEq(admSupply, 10000e18);

        _creditNft = new MockCreditNft(100);
        vm.prank(admin);
        IManager.setCreditNftAddress(address(_creditNft));

        twapOracleAddress = address(diamond);
        dollarTokenAddress = address(IDollar);
        creditNftManagerAddress = address(diamond);
        creditCalculatorAddress = IManager.creditCalculatorAddress();
        creditNftAddress = address(_creditNft);
        governanceTokenAddress = IManager.governanceTokenAddress();
        // deploy credit token
        MockCreditToken _creditToken = new MockCreditToken(0);
        creditTokenAddress = address(_creditToken);
        vm.prank(admin);
        IManager.setCreditTokenAddress(creditTokenAddress);

        // set this contract as minter
        vm.startPrank(admin);
        IAccessCtrl.grantRole(DOLLAR_TOKEN_MINTER_ROLE, address(this));
        vm.stopPrank();
    }

    function mockTwapFuncs(uint256 _twapPrice) public {
        uint256 TWAP_ORACLE_STORAGE_POSITION = uint256(
            keccak256("diamond.standard.twap.oracle.storage")
        ) - 1;
        uint256 dollarPricePosition = TWAP_ORACLE_STORAGE_POSITION + 2;
        vm.store(
            address(diamond),
            bytes32(dollarPricePosition),
            bytes32(_twapPrice)
        );
    }

    function mockDollarMintCalcFuncs(uint256 _dollarsToMint) public {
        vm.mockCall(
            address(diamond),
            abi.encodeWithSelector(
                DollarMintCalculatorFacet.getDollarsToMint.selector
            ),
            abi.encode(_dollarsToMint)
        );
    }

    function test_setExpiredCreditNftConversionRate() public {
        vm.expectRevert("Caller is not a Credit NFT manager");
        ICreditNftMgrFacet.setExpiredCreditNftConversionRate(100);

        vm.prank(admin);
        ICreditNftMgrFacet.setExpiredCreditNftConversionRate(100);
        assertEq(ICreditNftMgrFacet.expiredCreditNftConversionRate(), 100);
    }

    function test_setCreditNftLength() public {
        vm.expectRevert("Caller is not a Credit NFT manager");
        ICreditNftMgrFacet.setCreditNftLength(100);

        vm.prank(admin);
        ICreditNftMgrFacet.setCreditNftLength(100);
        assertEq(ICreditNftMgrFacet.creditNftLengthBlocks(), 100);
    }

    function test_exchangeDollarsForCreditNft() public {
        mockTwapFuncs(2e18);
        vm.expectRevert("Price must be below 1 to mint Credit NFT");
        ICreditNftMgrFacet.exchangeDollarsForCreditNft(100);

        mockTwapFuncs(5e17);
        address mockSender = address(0x123);
        vm.roll(10000);
        // Mint some dollarTokens to mockSender and then approve all
        MockDollarToken(dollarTokenAddress).mint(mockSender, 10000e18);
        vm.startPrank(mockSender);

        MockDollarToken(dollarTokenAddress).approve(
            creditNftManagerAddress,
            10000e18
        );

        uint256 expiryBlockNumber = ICreditNftMgrFacet
            .exchangeDollarsForCreditNft(100);
        assertEq(expiryBlockNumber, 10000 + creditNftLengthBlocks);
    }

    function test_exchangeDollarsForCreditRevertsIfPriceHigherThan1Ether()
        public
    {
        mockTwapFuncs(2e18);
        vm.expectRevert("Price must be below 1 to mint Credit");
        ICreditNftMgrFacet.exchangeDollarsForCredit(100);
    }

    function test_exchangeDollarsForCreditWorks() public {
        mockTwapFuncs(5e17);
        address mockSender = address(0x123);
        vm.roll(10000); // Mint some dollarTokens to mockSender and then approve all
        MockDollarToken(dollarTokenAddress).mint(mockSender, 10000e18);
        vm.startPrank(mockSender);

        MockDollarToken(dollarTokenAddress).approve(
            creditNftManagerAddress,
            10000e18
        );

        uint256 creditAmount = ICreditNftMgrFacet.exchangeDollarsForCredit(100);
        assertEq(creditAmount, 100);
    }

    function test_burnExpiredCreditNftForGovernanceRevertsIfNotExpired()
        public
    {
        vm.roll(1000);
        vm.expectRevert("Credit NFT has not expired");
        ICreditNftMgrFacet.burnExpiredCreditNftForGovernance(2000, 1e18);
    }

    function test_burnExpiredCreditNftForGovernanceRevertsIfNotEnoughBalance()
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
        vm.expectRevert("User not enough Credit NFT");
        ICreditNftMgrFacet.burnExpiredCreditNftForGovernance(500, 1e18);
    }

    function test_burnExpiredCreditNftForGovernanceWorks() public {
        address mockMessageSender = address(0x123);
        uint256 expiryBlockNumber = 500;
        vm.startPrank(admin);
        MockCreditNft(creditNftAddress).mintCreditNft(
            mockMessageSender,
            2e18,
            expiryBlockNumber
        );
        IAccessCtrl.grantRole(
            keccak256("GOVERNANCE_TOKEN_MINTER_ROLE"),
            creditNftManagerAddress
        );
        vm.stopPrank();
        vm.roll(1000);
        vm.prank(mockMessageSender);
        ICreditNftMgrFacet.burnExpiredCreditNftForGovernance(
            expiryBlockNumber,
            1e18
        );
        uint256 governanceBalance = IERC20Ubiquity(governanceTokenAddress)
            .balanceOf(mockMessageSender);
        assertEq(governanceBalance, 5e17);
    }

    function test_burnCreditNftForCreditRevertsIfExpired() public {
        vm.warp(1000);
        vm.expectRevert("Credit NFT has expired");
        ICreditNftMgrFacet.burnCreditNftForCredit(500, 1e18);
    }

    function test_burnCreditNftForCreditRevertsIfNotEnoughBalance() public {
        vm.warp(1000);
        vm.expectRevert("User not enough Credit NFT");
        ICreditNftMgrFacet.burnCreditNftForCredit(1001, 1e18);
    }

    function test_burnCreditNftForCreditWorks() public {
        address mockMessageSender = address(0x123);
        uint256 expiryBlockNumber = 500;
        vm.startPrank(admin);
        MockCreditNft(creditNftAddress).mintCreditNft(
            mockMessageSender,
            2e18,
            expiryBlockNumber
        );
        IAccessCtrl.grantRole(
            keccak256("GOVERNANCE_TOKEN_MINTER_ROLE"),
            creditNftManagerAddress
        );
        vm.stopPrank();
        vm.prank(mockMessageSender);
        vm.warp(expiryBlockNumber - 1);
        ICreditNftMgrFacet.burnCreditNftForCredit(expiryBlockNumber, 1e18);
        uint256 redeemBalance = UbiquityCreditToken(creditTokenAddress)
            .balanceOf(mockMessageSender);
        assertEq(redeemBalance, 1e18);
    }

    function test_burnCreditTokensForDollarsRevertsIfPriceLowerThan1Ether()
        public
    {
        mockTwapFuncs(5e17);
        vm.expectRevert("Price must be above 1");
        ICreditNftMgrFacet.burnCreditTokensForDollars(100);
    }

    function test_burnCreditTokensForDollarsIfNotEnoughBalance() public {
        mockTwapFuncs(2e18);
        vm.expectRevert("User doesn't have enough Credit pool tokens.");
        ICreditNftMgrFacet.burnCreditTokensForDollars(100);
    }

    function test_burnCreditTokensForDollarsWorks() public {
        mockTwapFuncs(2e18);
        mockDollarMintCalcFuncs(1e18);
        address account1 = address(0x123);
        MockCreditToken(creditTokenAddress).mint(account1, 100e18);
        vm.prank(account1);
        uint256 unredeemed = ICreditNftMgrFacet.burnCreditTokensForDollars(
            10e18
        );
        assertEq(unredeemed, 10e18 - 1e18);
    }

    function test_redeemCreditNftRevertsIfPriceLowerThan1Ether() public {
        mockTwapFuncs(5e17);
        vm.expectRevert("Price must be above 1 to redeem Credit NFT");
        ICreditNftMgrFacet.redeemCreditNft(123123123, 100);
    }

    function test_redeemCreditNftRevertsIfCreditNftExpired() public {
        mockTwapFuncs(2e18);
        vm.roll(10000);
        vm.expectRevert("Credit NFT has expired");
        ICreditNftMgrFacet.redeemCreditNft(5555, 100);
    }

    function test_redeemCreditNftRevertsIfNotEnoughBalance() public {
        mockTwapFuncs(2e18);
        address account1 = address(0x123);
        uint256 expiryBlockNumber = 123123;
        MockCreditNft(creditNftAddress).mintCreditNft(
            account1,
            100,
            expiryBlockNumber
        );
        vm.expectRevert("User not enough Credit NFT");
        vm.prank(account1);
        vm.roll(expiryBlockNumber - 1);
        ICreditNftMgrFacet.redeemCreditNft(expiryBlockNumber, 200);
    }

    function test_redeemCreditNftRevertsIfNotEnoughDollars() public {
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
        vm.mockCall(
            address(diamond),
            abi.encodeWithSelector(
                DollarMintExcessFacet.distributeDollars.selector
            ),
            abi.encode()
        );

        vm.prank(account1);
        vm.expectRevert("There aren't enough Dollar to redeem currently");
        vm.roll(expiryBlockNumber - 1);
        ICreditNftMgrFacet.redeemCreditNft(expiryBlockNumber, 99);
    }

    function test_redeemCreditNftRevertsIfZeroAmountOfDollars() public {
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

        vm.mockCall(
            address(diamond),
            abi.encodeWithSelector(
                DollarMintExcessFacet.distributeDollars.selector
            ),
            abi.encode()
        );

        vm.prank(account1);
        vm.expectRevert("There aren't any Dollar to redeem currently");
        vm.roll(expiryBlockNumber - 1);
        ICreditNftMgrFacet.redeemCreditNft(expiryBlockNumber, 99);
    }

    function test_redeemCreditNftWorks() public {
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
        vm.mockCall(
            address(diamond),
            abi.encodeWithSelector(
                DollarMintExcessFacet.distributeDollars.selector
            ),
            abi.encode()
        );
        vm.prank(account1);
        vm.roll(expiryBlockNumber - 1);
        uint256 unredeemedCreditNft = ICreditNftMgrFacet.redeemCreditNft(
            expiryBlockNumber,
            99
        );
        assertEq(unredeemedCreditNft, 0);
    }

    function test_mintClaimableDollars() public {
        mockDollarMintCalcFuncs(50);
        // set excess dollar distributor for creditNftAddress

        vm.mockCall(
            address(diamond),
            abi.encodeWithSelector(
                DollarMintExcessFacet.distributeDollars.selector
            ),
            abi.encode()
        );

        uint256 beforeBalance = MockDollarToken(dollarTokenAddress).balanceOf(
            creditNftManagerAddress
        );
        ICreditNftMgrFacet.mintClaimableDollars();
        uint256 afterBalance = MockDollarToken(dollarTokenAddress).balanceOf(
            creditNftManagerAddress
        );
        assertEq(afterBalance - beforeBalance, 50);
    }
}
