// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../DiamondTestSetup.sol";
import {CreditNftManagerFacet} from "../../../src/dollar/facets/CreditNftManagerFacet.sol";
import {CreditRedemptionCalculatorFacet} from "../../../src/dollar/facets/CreditRedemptionCalculatorFacet.sol";
import {DollarMintCalculatorFacet} from "../../../src/dollar/facets/DollarMintCalculatorFacet.sol";
import {DollarMintExcessFacet} from "../../../src/dollar/facets/DollarMintExcessFacet.sol";
import {TWAPOracleDollar3poolFacet} from "../../../src/dollar/facets/TWAPOracleDollar3poolFacet.sol";
import "../../../src/dollar/libraries/Constants.sol";
import {IERC20Ubiquity} from "../../../src/dollar/interfaces/IERC20Ubiquity.sol";
import {CreditNft} from "../../../src/dollar/core/CreditNft.sol";
import {UbiquityCreditToken} from "../../../src/dollar/core/UbiquityCreditToken.sol";

contract CreditNftManagerFacetTest is DiamondTestSetup {
    CreditNft _creditNft;
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
        dollarToken.mint(admin, 10000e18);
        uint256 admSupply = dollarToken.balanceOf(admin);
        assertEq(admSupply, 10000e18);

        _creditNft = creditNft;
        vm.prank(admin);
        managerFacet.setCreditNftAddress(address(_creditNft));

        twapOracleAddress = address(diamond);
        dollarTokenAddress = address(dollarToken);
        creditNftManagerAddress = address(diamond);
        creditCalculatorAddress = managerFacet.creditCalculatorAddress();
        creditNftAddress = address(_creditNft);
        governanceTokenAddress = managerFacet.governanceTokenAddress();
        // deploy credit token
        UbiquityCreditToken _creditToken = creditToken;
        creditTokenAddress = address(_creditToken);
        vm.prank(admin);
        managerFacet.setCreditTokenAddress(creditTokenAddress);

        // set this contract as minter
        vm.startPrank(admin);
        accessControlFacet.grantRole(DOLLAR_TOKEN_MINTER_ROLE, address(this));
        accessControlFacet.grantRole(CREDIT_TOKEN_MINTER_ROLE, address(this));
        accessControlFacet.grantRole(
            GOVERNANCE_TOKEN_MINTER_ROLE,
            address(diamond)
        );
        accessControlFacet.grantRole(CREDIT_NFT_MANAGER_ROLE, address(diamond));
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
        creditNftManagerFacet.setExpiredCreditNftConversionRate(100);

        vm.prank(admin);
        creditNftManagerFacet.setExpiredCreditNftConversionRate(100);
        assertEq(creditNftManagerFacet.expiredCreditNftConversionRate(), 100);
    }

    function test_setCreditNftLength() public {
        vm.expectRevert("Caller is not a Credit NFT manager");
        creditNftManagerFacet.setCreditNftLength(100);

        vm.prank(admin);
        creditNftManagerFacet.setCreditNftLength(100);
        assertEq(creditNftManagerFacet.creditNftLengthBlocks(), 100);
    }

    function test_exchangeDollarsForCreditNft() public {
        mockTwapFuncs(2e18);
        vm.expectRevert("Price must be below 1 to mint Credit NFT");
        creditNftManagerFacet.exchangeDollarsForCreditNft(100);

        mockTwapFuncs(5e17);
        address mockSender = address(0x123);
        vm.roll(10000);
        // Mint some dollarTokens to mockSender and then approve all
        dollarToken.mint(mockSender, 10000e18);
        vm.startPrank(mockSender);

        dollarToken.approve(creditNftManagerAddress, 10000e18);

        uint256 expiryBlockNumber = creditNftManagerFacet
            .exchangeDollarsForCreditNft(100);
        assertEq(expiryBlockNumber, 10000 + creditNftLengthBlocks);
    }

    function test_exchangeDollarsForCreditRevertsIfPriceHigherThan1Ether()
        public
    {
        mockTwapFuncs(2e18);
        vm.expectRevert("Price must be below 1 to mint Credit");
        creditNftManagerFacet.exchangeDollarsForCredit(100);
    }

    function test_exchangeDollarsForCreditWorks() public {
        mockTwapFuncs(5e17);
        address mockSender = address(0x123);
        vm.roll(10000); // Mint some dollarTokens to mockSender and then approve all
        dollarToken.mint(mockSender, 10000e18);
        vm.startPrank(mockSender);

        dollarToken.approve(creditNftManagerAddress, 10000e18);

        uint256 creditAmount = creditNftManagerFacet.exchangeDollarsForCredit(
            100
        );
        assertEq(creditAmount, 100);
    }

    function test_burnExpiredCreditNftForGovernanceRevertsIfNotExpired()
        public
    {
        vm.roll(1000);
        vm.expectRevert("Credit NFT has not expired");
        creditNftManagerFacet.burnExpiredCreditNftForGovernance(2000, 1e18);
    }

    function test_burnExpiredCreditNftForGovernanceRevertsIfNotEnoughBalance()
        public
    {
        address mockMessageSender = address(0x123);
        vm.prank(admin);
        creditNft.mintCreditNft(mockMessageSender, 100, 500);
        vm.roll(1000);
        vm.prank(mockMessageSender);
        vm.expectRevert("User not enough Credit NFT");
        creditNftManagerFacet.burnExpiredCreditNftForGovernance(500, 1e18);
    }

    function test_burnExpiredCreditNftForGovernanceWorks() public {
        address mockMessageSender = address(0x123);
        uint256 expiryBlockNumber = 500;
        vm.startPrank(admin);
        creditNft.mintCreditNft(mockMessageSender, 2e18, expiryBlockNumber);
        accessControlFacet.grantRole(
            keccak256("GOVERNANCE_TOKEN_MINTER_ROLE"),
            creditNftManagerAddress
        );
        vm.stopPrank();
        vm.roll(1000);
        vm.startPrank(mockMessageSender);
        creditNft.setApprovalForAll(address(diamond), true);
        creditNftManagerFacet.burnExpiredCreditNftForGovernance(
            expiryBlockNumber,
            1e18
        );
        vm.stopPrank();
        uint256 governanceBalance = IERC20Ubiquity(governanceTokenAddress)
            .balanceOf(mockMessageSender);
        assertEq(governanceBalance, 5e17);
    }

    function test_burnCreditNftForCreditRevertsIfExpired() public {
        vm.warp(1000);
        vm.expectRevert("Credit NFT has expired");
        creditNftManagerFacet.burnCreditNftForCredit(500, 1e18);
    }

    function test_burnCreditNftForCreditRevertsIfNotEnoughBalance() public {
        vm.warp(1000);
        vm.expectRevert("User not enough Credit NFT");
        creditNftManagerFacet.burnCreditNftForCredit(1001, 1e18);
    }

    function test_burnCreditNftForCreditWorks() public {
        address mockMessageSender = address(0x123);
        uint256 expiryBlockNumber = 500;
        vm.startPrank(admin);

        creditNft.mintCreditNft(mockMessageSender, 2e18, expiryBlockNumber);
        accessControlFacet.grantRole(
            keccak256("GOVERNANCE_TOKEN_MINTER_ROLE"),
            creditNftManagerAddress
        );
        vm.stopPrank();
        vm.startPrank(mockMessageSender);
        vm.warp(expiryBlockNumber - 1);
        creditNft.setApprovalForAll(address(diamond), true);
        creditNftManagerFacet.burnCreditNftForCredit(expiryBlockNumber, 1e18);
        vm.stopPrank();
        uint256 redeemBalance = creditToken.balanceOf(mockMessageSender);
        assertEq(redeemBalance, 1e18);
    }

    function test_burnCreditTokensForDollarsRevertsIfPriceLowerThan1Ether()
        public
    {
        mockTwapFuncs(5e17);
        vm.expectRevert("Price must be above 1");
        creditNftManagerFacet.burnCreditTokensForDollars(100);
    }

    function test_burnCreditTokensForDollarsIfNotEnoughBalance() public {
        mockTwapFuncs(2e18);
        vm.expectRevert("User doesn't have enough Credit pool tokens.");
        creditNftManagerFacet.burnCreditTokensForDollars(100);
    }

    function test_burnCreditTokensForDollarsWorks() public {
        mockTwapFuncs(2e18);
        mockDollarMintCalcFuncs(1e18);
        address account1 = address(0x123);
        UbiquityCreditToken(creditTokenAddress).mint(account1, 100e18);
        vm.prank(account1);
        uint256 unredeemed = creditNftManagerFacet.burnCreditTokensForDollars(
            10e18
        );
        assertEq(unredeemed, 10e18 - 1e18);
    }

    function test_redeemCreditNftRevertsIfPriceLowerThan1Ether() public {
        mockTwapFuncs(5e17);
        vm.expectRevert("Price must be above 1 to redeem Credit NFT");
        creditNftManagerFacet.redeemCreditNft(123123123, 100);
    }

    function test_redeemCreditNftRevertsIfCreditNftExpired() public {
        mockTwapFuncs(2e18);
        vm.roll(10000);
        vm.expectRevert("Credit NFT has expired");
        creditNftManagerFacet.redeemCreditNft(5555, 100);
    }

    function test_redeemCreditNftRevertsIfNotEnoughBalance() public {
        vm.startPrank(admin);
        accessControlFacet.grantRole(CREDIT_NFT_MANAGER_ROLE, address(this));
        accessControlFacet.grantRole(
            GOVERNANCE_TOKEN_MINTER_ROLE,
            address(this)
        );
        vm.stopPrank();

        mockTwapFuncs(2e18);
        address account1 = address(0x123);
        uint256 expiryBlockNumber = 123123;
        creditNft.mintCreditNft(account1, 100, expiryBlockNumber);
        vm.expectRevert("User not enough Credit NFT");
        vm.prank(account1);
        vm.roll(expiryBlockNumber - 1);
        creditNftManagerFacet.redeemCreditNft(expiryBlockNumber, 200);
    }

    function test_redeemCreditNftRevertsIfNotEnoughDollars() public {
        vm.startPrank(admin);
        accessControlFacet.grantRole(CREDIT_NFT_MANAGER_ROLE, address(this));
        accessControlFacet.grantRole(
            GOVERNANCE_TOKEN_MINTER_ROLE,
            address(this)
        );
        vm.stopPrank();

        mockTwapFuncs(2e18);
        address account1 = address(0x123);
        uint256 expiryBlockNumber = 123123;
        creditNft.mintCreditNft(account1, 100, expiryBlockNumber);
        UbiquityCreditToken(creditTokenAddress).mint(
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
        creditNftManagerFacet.redeemCreditNft(expiryBlockNumber, 99);
    }

    function test_redeemCreditNftRevertsIfZeroAmountOfDollars() public {
        vm.startPrank(admin);
        accessControlFacet.grantRole(CREDIT_NFT_MANAGER_ROLE, address(this));
        accessControlFacet.grantRole(
            GOVERNANCE_TOKEN_MINTER_ROLE,
            address(this)
        );
        vm.stopPrank();

        mockTwapFuncs(2e18);
        mockDollarMintCalcFuncs(0);
        address account1 = address(0x123);
        uint256 expiryBlockNumber = 123123;
        creditNft.mintCreditNft(account1, 100, expiryBlockNumber);
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
        creditNftManagerFacet.redeemCreditNft(expiryBlockNumber, 99);
    }

    function test_redeemCreditNftWorks() public {
        vm.startPrank(admin);
        accessControlFacet.grantRole(CREDIT_NFT_MANAGER_ROLE, address(this));
        accessControlFacet.grantRole(
            GOVERNANCE_TOKEN_MINTER_ROLE,
            address(this)
        );
        vm.stopPrank();

        mockTwapFuncs(2e18);
        mockDollarMintCalcFuncs(20000e18);
        address account1 = address(0x123);
        uint256 expiryBlockNumber = 123123;
        creditNft.mintCreditNft(account1, 100, expiryBlockNumber);
        creditToken.mint(creditNftManagerAddress, 10000e18);

        // set excess dollar distributor for debtCouponAddress
        vm.mockCall(
            address(diamond),
            abi.encodeWithSelector(
                DollarMintExcessFacet.distributeDollars.selector
            ),
            abi.encode()
        );
        vm.startPrank(account1);
        creditNft.setApprovalForAll(address(diamond), true);
        vm.roll(expiryBlockNumber - 1);
        uint256 unredeemedCreditNft = creditNftManagerFacet.redeemCreditNft(
            expiryBlockNumber,
            99
        );
        vm.stopPrank();

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

        uint256 beforeBalance = dollarToken.balanceOf(creditNftManagerAddress);
        creditNftManagerFacet.mintClaimableDollars();
        uint256 afterBalance = dollarToken.balanceOf(creditNftManagerAddress);
        assertEq(afterBalance - beforeBalance, 50);
    }
}
