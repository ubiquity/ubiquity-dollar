// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ManagerFacet} from "../../../src/dollar/facets/ManagerFacet.sol";
import {CreditNft} from "../../../src/dollar/core/CreditNft.sol";

import "../../helpers/LocalTestHelper.sol";

contract CreditNftTest is LocalTestHelper {
    address dollarManagerAddress;
    address creditNftAddress;
    CreditNft creditNft;

    event MintedCreditNft(
        address recipient,
        uint256 expiryBlock,
        uint256 amount
    );

    event BurnedCreditNft(
        address creditNftHolder,
        uint256 expiryBlock,
        uint256 amount
    );

    function setUp() public override {
        super.setUp();

        // deploy Credit NFT token
        creditNft = new CreditNft(address(diamond));
        creditNftAddress = address(creditNft);
        vm.prank(admin);
        IManager.setCreditNftAddress(address(creditNftAddress));
    }

    function testSetManager_ShouldRevert_WhenNotAdmin() public {
        vm.prank(address(0x123abc));
        vm.expectRevert("ERC20Ubiquity: not admin");
        creditNft.setManager(address(0x123abc));
    }

    function testSetManager_ShouldSetDiamond() public {
        address newDiamond = address(0x123abc);
        vm.prank(admin);
        creditNft.setManager(newDiamond);
        require(creditNft.getManager() == newDiamond);
    }

    function testMintCreditNft_ShouldRevert_WhenNotCreditNftManager() public {
        vm.expectRevert("Caller is not a CreditNft manager");
        creditNft.mintCreditNft(address(0x123), 1, 100);
    }

    function testMintCreditNft_ShouldMintCreditNft() public {
        address receiver = address(0x123);
        uint256 expiryBlockNumber = 100;
        uint256 mintAmount = 1;

        uint256 init_balance = creditNft.balanceOf(receiver, expiryBlockNumber);
        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit MintedCreditNft(receiver, expiryBlockNumber, 1);
        creditNft.mintCreditNft(receiver, mintAmount, expiryBlockNumber);
        uint256 last_balance = creditNft.balanceOf(receiver, expiryBlockNumber);
        assertEq(last_balance - init_balance, mintAmount);

        uint256[] memory holderTokens = creditNft.holderTokens(receiver);
        assertEq(holderTokens[0], expiryBlockNumber);
    }

    function testBurnCreditNft_ShouldRevert_WhenNotCreditNftManager() public {
        vm.expectRevert("Caller is not a CreditNft manager");
        creditNft.burnCreditNft(address(0x123), 1, 100);
    }

    function testBurnCreditNft_ShouldBurnCreditNft() public {
        address creditNftOwner = address(0x123);
        uint256 expiryBlockNumber = 100;
        uint256 burnAmount = 1;

        vm.prank(admin);
        creditNft.mintCreditNft(creditNftOwner, 10, expiryBlockNumber);
        uint256 init_balance = creditNft.balanceOf(
            creditNftOwner,
            expiryBlockNumber
        );
        vm.prank(creditNftOwner);
        creditNft.setApprovalForAll(admin, true);
        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit BurnedCreditNft(creditNftOwner, expiryBlockNumber, 1);
        creditNft.burnCreditNft(creditNftOwner, burnAmount, expiryBlockNumber);
        uint256 last_balance = creditNft.balanceOf(
            creditNftOwner,
            expiryBlockNumber
        );
        assertEq(init_balance - last_balance, burnAmount);
    }

    //function testUpdateTotalDebt_ShouldUpdateTotalDebt() public {
    //    vm.startPrank(admin);
    //    creditNft.mintCreditNft(address(0x111), 10, 10000); // 10 -> amount, 10000 -> expiryBlockNumber
    //    creditNft.mintCreditNft(address(0x222), 10, 20000);
    //    creditNft.mintCreditNft(address(0x333), 10, 30000);
    //    vm.stopPrank();

        // sets block.number
    //    vm.roll(block.number + 15000);
    //    creditNft.updateTotalDebt();
    //    uint256 outStandingTotalDebt = creditNft.getTotalOutstandingDebt();
    //    assertEq(outStandingTotalDebt, 20);
    //}

    //function testGetTotalOutstandingDebt_ReturnTotalDebt() public {
    //    vm.startPrank(admin);
    //    creditNft.mintCreditNft(address(0x111), 10, 10000); // 10 -> amount, 10000 -> expiryBlockNumber
    //    creditNft.mintCreditNft(address(0x222), 10, 20000);
    //    creditNft.mintCreditNft(address(0x333), 10, 30000);
    //    vm.stopPrank();

        // sets block.number
    //    vm.roll(block.number + 25000);
    //    creditNft.updateTotalDebt();
    //    uint256 outStandingTotalDebt = creditNft.getTotalOutstandingDebt();
    //    assertEq(outStandingTotalDebt, 10);
    //}
}
