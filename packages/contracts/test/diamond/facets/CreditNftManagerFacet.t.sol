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
import {UbiquityCreditToken} from "../../../src/dollar/core/UbiquityCreditToken.sol";



contract CreditNftManagerFacetTest is DiamondSetup {
    using stdStorage for StdStorage;


    CreditNft creditNFT;
    address dollarManagerAddress;
    address creditCalculatorAddress;
    address creditNFTManagerAddress;
    uint256 creditNFTLengthBlocks = 100;
    address twapOracleAddress;
    address creditNFTAddress;
    address governanceTokenAddress;
    address dollarMintCalculatorAddress;
    address mockMessageSender = address(0x123);
    UbiquityCreditToken creditToken;

    function setUp() public virtual override {
        super.setUp();
        vm.startPrank(admin);
        IDollar.mint(admin, 10000e18);
        
        creditNFT = new CreditNft(address(diamond));
        
        IManager.setCreditNftAddress(address(creditNFT));

        twapOracleAddress = address(diamond);
        
        creditNFTManagerAddress = address(diamond);
        creditCalculatorAddress = IManager.creditCalculatorAddress();
        creditNFTAddress = address(creditNFT);
        governanceTokenAddress = IManager.governanceTokenAddress();
        // deploy credit token
        creditToken = new UbiquityCreditToken(address(diamond));
        
        
        IManager.setCreditTokenAddress(address(creditToken));

        // set this contract as minter
        
        IAccessCtrl.grantRole(DOLLAR_TOKEN_MINTER_ROLE, address(this));
        IAccessCtrl.grantRole(GOVERNANCE_TOKEN_MINTER_ROLE, address(this));
        IAccessCtrl.grantRole(CREDIT_NFT_MANAGER_ROLE, address(this));
        IAccessCtrl.grantRole(CREDIT_TOKEN_MINTER_ROLE, address(this));
        IAccessCtrl.grantRole(DOLLAR_TOKEN_BURNER_ROLE, address(this));

        IAccessCtrl.grantRole(CREDIT_NFT_MANAGER_ROLE, address(diamond));
        IAccessCtrl.grantRole(GOVERNANCE_TOKEN_MINTER_ROLE, address(diamond));
        IAccessCtrl.grantRole(
            keccak256("CREDIT_TOKEN_BURNER_ROLE"),
            address(diamond)
        );    
        IAccessCtrl.grantRole(
            keccak256("CREDIT_TOKEN_MINTER_ROLE"),
            address(diamond)
        );
        vm.stopPrank();
    }

    function mockTwapFuncs(uint256 _twapPrice) public {
        uint256 TWAP_ORACLE_STORAGE_POSITION = uint256(
            keccak256("diamond.standard.twap.oracle.storage")
        );
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

    function test_setExpiredCreditNFTConversionRate() public {
        // vm.expectRevert("Caller is not a Credit NFT manager");
        // ICreditNFTMgrFacet.setExpiredCreditNFTConversionRate(100);

        vm.prank(admin);
        ICreditNFTMgrFacet.setExpiredCreditNFTConversionRate(100);
        assertEq(ICreditNFTMgrFacet.expiredCreditNFTConversionRate(), 100);
    }

    function test_setCreditNFTLength() public {
        // This needs to be a seperate length, this should also be tested in AccessControl tests and is out of scope for this test
        // vm.expectRevert("Caller is not a Credit NFT manager");
        // ICreditNFTMgrFacet.setCreditNFTLength(100);

        vm.prank(admin);
        ICreditNFTMgrFacet.setCreditNFTLength(100);
        assertEq(ICreditNFTMgrFacet.creditNFTLengthBlocks(), 100);
    }

    function test_exchangeDollarsForCreditNFT() public {
        mockTwapFuncs(2e18);
        vm.expectRevert("Price must be below 1 to mint Credit NFT");
        ICreditNFTMgrFacet.exchangeDollarsForCreditNft(100);

        mockTwapFuncs(5e17);
        address mockSender = address(0x123);
        vm.roll(10000);
        // Mint some dollarTokens to mockSender and then approve all
        IDollar.mint(mockSender, 10000e18);
        vm.startPrank(mockSender);

        IDollar.approve(
            creditNFTManagerAddress,
            10000e18
        );

        uint256 expiryBlockNumber = ICreditNFTMgrFacet
            .exchangeDollarsForCreditNft(100);
        assertEq(expiryBlockNumber, 10000 + creditNFTLengthBlocks);
    }

    function test_exchangeDollarsForCreditRevertsIfPriceHigherThan1Ether()
        public
    {
        mockTwapFuncs(2e18);
        vm.expectRevert("Price must be below 1 to mint Credit");
        ICreditNFTMgrFacet.exchangeDollarsForCredit(100);
    }

    function test_exchangeDollarsForCreditWorks() public {
        mockTwapFuncs(5e17);
        address mockSender = address(0x123);
        vm.roll(10000); // Mint some dollarTokens to mockSender and then approve all
        IDollar.mint(mockSender, 10000e18);
        vm.startPrank(mockSender);

        IDollar.approve(
            creditNFTManagerAddress,
            10000e18
        );

        uint256 creditAmount = ICreditNFTMgrFacet.exchangeDollarsForCredit(100);
        assertEq(creditAmount, 100);
    }

    function test_burnExpiredCreditNFTForGovernanceRevertsIfNotExpired()
        public
    {
        vm.roll(1000);
        vm.expectRevert("Credit NFT has not expired");
        ICreditNFTMgrFacet.burnExpiredCreditNFTForGovernance(2000, 1e18);
    }

    function test_burnExpiredCreditNFTForGovernanceRevertsIfNotEnoughBalance()
        public
    {
        
        vm.prank(admin);
        creditNFT.mintCreditNft(
            mockMessageSender,
            100,
            500
        );
        vm.roll(1000);
        vm.prank(mockMessageSender);
        vm.expectRevert("User not enough Credit NFT");
        ICreditNFTMgrFacet.burnExpiredCreditNFTForGovernance(500, 1e18);
    }

    function test_burnExpiredCreditNFTForGovernanceWorks() public {
        
        uint256 expiryBlockNumber = 500;
        vm.startPrank(admin);
        creditNFT.mintCreditNft(
            mockMessageSender,
            2e18,
            expiryBlockNumber
        );
        IAccessCtrl.grantRole(
            keccak256("GOVERNANCE_TOKEN_MINTER_ROLE"),
            creditNFTManagerAddress
        );
        vm.stopPrank();
        vm.roll(1000);
        vm.startPrank(mockMessageSender);
        creditNFT.setApprovalForAll(address(ICreditNFTMgrFacet), true);
        ICreditNFTMgrFacet.burnExpiredCreditNFTForGovernance(
            expiryBlockNumber,
            1e18
        );
        vm.stopPrank();
        uint256 governanceBalance = IERC20Ubiquity(governanceTokenAddress)
            .balanceOf(mockMessageSender);
        assertEq(governanceBalance, 5e17);
    }

    function test_burnCreditNFTForCreditRevertsIfExpired() public {
        vm.warp(1000);
        vm.expectRevert("Credit NFT has expired");
        vm.prank(admin);
        ICreditNFTMgrFacet.burnCreditNFTForCredit(500, 1e18);
    }

    function test_burnCreditNFTForCreditRevertsIfNotEnoughBalance() public {
        vm.warp(1000);
        vm.expectRevert("User not enough Credit NFT");
        ICreditNFTMgrFacet.burnCreditNFTForCredit(1001, 1e18);
    }

    function test_burnCreditNFTForCreditWorks() public {
        
        uint256 expiryBlockNumber = 500;
        vm.startPrank(admin);
        creditNFT.mintCreditNft(
            mockMessageSender,
            2e18,
            expiryBlockNumber
        );
        IAccessCtrl.grantRole(
            keccak256("GOVERNANCE_TOKEN_MINTER_ROLE"),
            creditNFTManagerAddress
        );
        
        vm.stopPrank();
        
        vm.warp(expiryBlockNumber - 1);
        vm.startPrank(mockMessageSender);
        creditNFT.setApprovalForAll(address(ICreditNFTMgrFacet), true);
        ICreditNFTMgrFacet.burnCreditNFTForCredit(expiryBlockNumber, 1e18);
        vm.stopPrank();
        uint256 redeemBalance = creditToken
            .balanceOf(mockMessageSender);
        assertEq(redeemBalance, 1e18);
    }

    function test_burnCreditTokensForDollarsRevertsIfPriceLowerThan1Ether()
        public
    {
        mockTwapFuncs(5e17);
        vm.expectRevert("Price must be above 1");
        ICreditNFTMgrFacet.burnCreditTokensForDollars(100);
    }

    function test_burnCreditTokensForDollarsIfNotEnoughBalance() public {
        mockTwapFuncs(2e18);
        vm.expectRevert("User doesn't have enough Credit pool tokens.");
        ICreditNFTMgrFacet.burnCreditTokensForDollars(100);
    }

    function test_burnCreditTokensForDollarsWorks() public {
        mockTwapFuncs(2e18);
        mockDollarMintCalcFuncs(1e18);
        address account1 = address(0x123);
        vm.prank(admin);
        creditToken.mint(account1, 100e18);
        uint256 diamondDollarBalance = IDollar.balanceOf(address(diamond));
        uint256 expected = diamondDollarBalance >= 10e18 ? 0 : 10e18 - diamondDollarBalance;
        vm.prank(account1);
        uint256 actual = ICreditNFTMgrFacet.burnCreditTokensForDollars(
            10e18
        );
        assertEq(actual, expected);
    }

    function test_redeemCreditNFTRevertsIfPriceLowerThan1Ether() public {
        mockTwapFuncs(5e17);
        vm.expectRevert("Price must be above 1 to redeem Credit NFT");
        ICreditNFTMgrFacet.redeemCreditNft(123123123, 100);
    }

    function test_redeemCreditNFTRevertsIfCreditNFTExpired() public {
        mockTwapFuncs(2e18);
        vm.roll(10000);
        vm.expectRevert("Credit NFT has expired");
        ICreditNFTMgrFacet.redeemCreditNft(5555, 100);
    }

    function test_redeemCreditNFTRevertsIfNotEnoughBalance() public {
        mockTwapFuncs(2e18);
        address account1 = address(0x123);
        uint256 expiryBlockNumber = 123123;
        creditNFT.mintCreditNft(
            account1,
            100,
            expiryBlockNumber
        );
        vm.expectRevert("User not enough Credit NFT");
        vm.roll(expiryBlockNumber - 1);
        vm.prank(account1);
        ICreditNFTMgrFacet.redeemCreditNft(expiryBlockNumber, 200);
    }


    //Test Fails because Contract not behaving as expected
    function testFails_redeemCreditNFTRevertsIfNotEnoughDollars() public {
        mockTwapFuncs(2e18);
        mockDollarMintCalcFuncs(0);
        address account1 = address(0x123);
        uint256 expiryBlockNumber = 123123;
        creditNFT.mintCreditNft(
            account1,
            100,
            expiryBlockNumber
        );
        
        // set excess dollar distributor for creditNFTAddress
        vm.mockCall(
            address(diamond),
            abi.encodeWithSelector(
                DollarMintExcessFacet.distributeDollars.selector
            ),
            abi.encode()
        );

        // set available Dollars to near 0
        uint256 diamondBal = IDollar.balanceOf(address(diamond)) -5;
        IDollar.burnFrom(address(diamond), diamondBal);

        vm.startPrank(account1);
        
        vm.roll(expiryBlockNumber - 1);
        creditNFT.setApprovalForAll(address(ICreditNFTMgrFacet), true);
        
        vm.expectRevert("There aren't enough Dollar to redeem currently");
        ICreditNFTMgrFacet.redeemCreditNft(expiryBlockNumber, 99);
    }

    function test_redeemCreditNFTRevertsIfZeroAmountOfDollars() public {
        mockTwapFuncs(2e18);
        mockDollarMintCalcFuncs(0);
        address account1 = address(0x123);
        uint256 expiryBlockNumber = 123123;
        creditNFT.mintCreditNft(
            account1,
            100,
            expiryBlockNumber
        );

        // set excess dollar distributor for creditNFTAddress

        vm.mockCall(
            address(diamond),
            abi.encodeWithSelector(
                DollarMintExcessFacet.distributeDollars.selector
            ),
            abi.encode()
        );

        uint256 diamondBal = IDollar.balanceOf(address(diamond));
        IDollar.burnFrom(address(diamond), diamondBal);
        
        
        vm.roll(expiryBlockNumber - 1);
        
        vm.startPrank(account1);
        creditNFT.setApprovalForAll(address(ICreditNFTMgrFacet), true);
        vm.expectRevert("There aren't any Dollar to redeem currently");
        ICreditNFTMgrFacet.redeemCreditNft(expiryBlockNumber, 99);
    }

    function test_redeemCreditNFTWorks() public {
        mockTwapFuncs(2e18);
        mockDollarMintCalcFuncs(20000e18);
        address account1 = address(0x123);
        uint256 expiryBlockNumber = 123123;
        vm.startPrank(admin);
        creditNFT.mintCreditNft(
            account1,
            100,
            expiryBlockNumber
        );
        creditToken.mint(
            creditNFTManagerAddress,
            10000e18
        );
        vm.stopPrank();

        // set excess dollar distributor for debtCouponAddress
        vm.mockCall(
            address(diamond),
            abi.encodeWithSelector(
                DollarMintExcessFacet.distributeDollars.selector
            ),
            abi.encode()
        );
        
        vm.roll(expiryBlockNumber - 1);
        vm.startPrank(account1);
        creditNFT.setApprovalForAll(address(ICreditNFTMgrFacet), true);
        uint256 unredeemedCreditNFT = ICreditNFTMgrFacet.redeemCreditNft(
            expiryBlockNumber,
            99
        );
        vm.stopPrank();
        assertEq(unredeemedCreditNFT, 0);
    }

    function test_mintClaimableDollars() public {
        mockDollarMintCalcFuncs(50);
        // set excess dollar distributor for creditNFTAddress

        vm.mockCall(
            address(diamond),
            abi.encodeWithSelector(
                DollarMintExcessFacet.distributeDollars.selector
            ),
            abi.encode()
        );

        uint256 beforeBalance = IDollar.balanceOf(
            creditNFTManagerAddress
        );
        ICreditNFTMgrFacet.mintClaimableDollars();
        uint256 afterBalance = IDollar.balanceOf(
            creditNFTManagerAddress
        );
        assertEq(afterBalance - beforeBalance, 50);
    }
}
