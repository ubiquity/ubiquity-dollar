// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {ManagerFacet} from "../../../src/diamond/facets/ManagerFacet.sol";
import {CreditNftForDiamond} from "../../../src/diamond/token/CreditNftForDiamond.sol";

import "../../helpers/LocalTestHelper.sol";

contract CreditNftTest is LocalTestHelper {
    address dollarManagerAddress;
    address creditNftAddress;
    CreditNftForDiamond creditNftForDiamond;
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
        creditNftForDiamond = new CreditNftForDiamond(address(diamond));
        creditNftAddress = address(creditNftForDiamond);
        vm.prank(admin);
        IManager.setCreditNftAddress(address(creditNftAddress));
    }

    function testMintCreditNft_ShouldRevert_WhenNotCreditNftManager() public {
        vm.expectRevert("Caller is not a CreditNft manager");
        creditNftForDiamond.mintCreditNft(address(0x123), 1, 100);
    }

    function testMintCreditNft_ShouldMintCreditNft() public {
        address receiver = address(0x123);
        uint256 expiryBlockNumber = 100;
        uint256 mintAmount = 1;

        uint256 init_balance = creditNftForDiamond.balanceOf(
            receiver,
            expiryBlockNumber
        );
        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit MintedCreditNft(receiver, expiryBlockNumber, 1);
        creditNftForDiamond.mintCreditNft(
            receiver,
            mintAmount,
            expiryBlockNumber
        );
        uint256 last_balance = creditNftForDiamond.balanceOf(
            receiver,
            expiryBlockNumber
        );
        assertEq(last_balance - init_balance, mintAmount);

        uint256[] memory holderTokens = creditNftForDiamond.holderTokens(
            receiver
        );
        assertEq(holderTokens[0], expiryBlockNumber);
    }

    function testBurnCreditNft_ShouldRevert_WhenNotCreditNftManager() public {
        vm.expectRevert("Caller is not a CreditNft manager");
        creditNftForDiamond.burnCreditNft(address(0x123), 1, 100);
    }

    function testBurnCreditNft_ShouldBurnCreditNft() public {
        address creditNftOwner = address(0x123);
        uint256 expiryBlockNumber = 100;
        uint256 burnAmount = 1;

        vm.prank(admin);
        creditNftForDiamond.mintCreditNft(
            creditNftOwner,
            10,
            expiryBlockNumber
        );
        uint256 init_balance = creditNftForDiamond.balanceOf(
            creditNftOwner,
            expiryBlockNumber
        );
        vm.prank(creditNftOwner);
        creditNftForDiamond.setApprovalForAll(admin, true);
        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit BurnedCreditNft(creditNftOwner, expiryBlockNumber, 1);
        creditNftForDiamond.burnCreditNft(
            creditNftOwner,
            burnAmount,
            expiryBlockNumber
        );
        uint256 last_balance = creditNftForDiamond.balanceOf(
            creditNftOwner,
            expiryBlockNumber
        );
        assertEq(init_balance - last_balance, burnAmount);
    }

    function testUpdateTotalDebt_ShouldUpdateTotalDebt() public {
        vm.startPrank(admin);
        creditNftForDiamond.mintCreditNft(address(0x111), 10, 10000); // 10 -> amount, 10000 -> expiryBlockNumber
        creditNftForDiamond.mintCreditNft(address(0x222), 10, 20000);
        creditNftForDiamond.mintCreditNft(address(0x333), 10, 30000);
        vm.stopPrank();

        // sets block.number
        vm.roll(block.number + 15000);
        creditNftForDiamond.updateTotalDebt();
        uint256 outStandingTotalDebt = creditNftForDiamond
            .getTotalOutstandingDebt();
        assertEq(outStandingTotalDebt, 20);
    }

    function testGetTotalOutstandingDebt_ReturnTotalDebt() public {
        vm.startPrank(admin);
        creditNftForDiamond.mintCreditNft(address(0x111), 10, 10000); // 10 -> amount, 10000 -> expiryBlockNumber
        creditNftForDiamond.mintCreditNft(address(0x222), 10, 20000);
        creditNftForDiamond.mintCreditNft(address(0x333), 10, 30000);
        vm.stopPrank();

        // sets block.number
        vm.roll(block.number + 25000);
        creditNftForDiamond.updateTotalDebt();
        uint256 outStandingTotalDebt = creditNftForDiamond
            .getTotalOutstandingDebt();
        assertEq(outStandingTotalDebt, 10);
    }
}
