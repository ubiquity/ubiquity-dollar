// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {UbiquityDollarManager} from
    "../../../src/dollar/core/UbiquityDollarManager.sol";
import {CreditNFT} from "../../../src/dollar/core/CreditNFT.sol";

import "../../helpers/LocalTestHelper.sol";

contract CreditNFTTest is LocalTestHelper {
    address dollarManagerAddress;
    address creditNFTAddress;

    event MintedCreditNFT(address recipient, uint256 expiryBlock, uint256 amount);

    event BurnedCreditNFT(
        address creditNFTHolder, uint256 expiryBlock, uint256 amount
    );

    function setUp() public {
        dollarManagerAddress = helpers_deployUbiquityDollarManager();
        creditNFTAddress = address(new CreditNFT(dollarManagerAddress));
    }

    function test_mintCreditNFTRevertsIfNotCreditNFTManager() public {
        vm.expectRevert("Caller is not a Credit NFT manager");
        CreditNFT(creditNFTAddress).mintCreditNFT(address(0x123), 1, 100);
    }

    function test_mintCreditNFTWorks() public {
        address receiver = address(0x123);
        uint256 expiryBlockNumber = 100;
        uint256 mintAmount = 1;

        uint256 init_balance =
            CreditNFT(creditNFTAddress).balanceOf(receiver, expiryBlockNumber);
        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit MintedCreditNFT(receiver, expiryBlockNumber, 1);
        CreditNFT(creditNFTAddress).mintCreditNFT(
            receiver, mintAmount, expiryBlockNumber
        );
        uint256 last_balance =
            CreditNFT(creditNFTAddress).balanceOf(receiver, expiryBlockNumber);
        assertEq(last_balance - init_balance, mintAmount);

        uint256[] memory holderTokens =
            CreditNFT(creditNFTAddress).holderTokens(receiver);
        assertEq(holderTokens[0], expiryBlockNumber);
    }

    function test_burnCreditNFTRevertsIfNotCreditNFTManager() public {
        vm.expectRevert("Caller is not a Credit NFT manager");
        CreditNFT(creditNFTAddress).burnCreditNFT(address(0x123), 1, 100);
    }

    function test_burnCreditNFTRevertsWorks() public {
        address creditNFTOwner = address(0x123);
        uint256 expiryBlockNumber = 100;
        uint256 burnAmount = 1;

        vm.prank(admin);
        CreditNFT(creditNFTAddress).mintCreditNFT(
            creditNFTOwner, 10, expiryBlockNumber
        );
        uint256 init_balance = CreditNFT(creditNFTAddress).balanceOf(
            creditNFTOwner, expiryBlockNumber
        );
        vm.prank(creditNFTOwner);
        CreditNFT(creditNFTAddress).setApprovalForAll(admin, true);
        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit BurnedCreditNFT(creditNFTOwner, expiryBlockNumber, 1);
        CreditNFT(creditNFTAddress).burnCreditNFT(
            creditNFTOwner, burnAmount, expiryBlockNumber
        );
        uint256 last_balance = CreditNFT(creditNFTAddress).balanceOf(
            creditNFTOwner, expiryBlockNumber
        );
        assertEq(init_balance - last_balance, burnAmount);
    }

    function test_updateTotalDebt() public {
        vm.startPrank(admin);
        CreditNFT(creditNFTAddress).mintCreditNFT(address(0x111), 10, 10000); // 10 -> amount, 10000 -> expiryBlockNumber
        CreditNFT(creditNFTAddress).mintCreditNFT(address(0x222), 10, 20000);
        CreditNFT(creditNFTAddress).mintCreditNFT(address(0x333), 10, 30000);
        vm.stopPrank();

        // sets block.number
        vm.roll(15000);
        CreditNFT(creditNFTAddress).updateTotalDebt();
        uint256 outStandingTotalDebt =
            CreditNFT(creditNFTAddress).getTotalOutstandingDebt();
        assertEq(outStandingTotalDebt, 20);
    }

    function test_getTotalOutstandingDebt() public {
        vm.startPrank(admin);
        CreditNFT(creditNFTAddress).mintCreditNFT(address(0x111), 10, 10000); // 10 -> amount, 10000 -> expiryBlockNumber
        CreditNFT(creditNFTAddress).mintCreditNFT(address(0x222), 10, 20000);
        CreditNFT(creditNFTAddress).mintCreditNFT(address(0x333), 10, 30000);
        vm.stopPrank();

        // sets block.number
        vm.roll(25000);
        CreditNFT(creditNFTAddress).updateTotalDebt();
        uint256 outStandingTotalDebt =
            CreditNFT(creditNFTAddress).getTotalOutstandingDebt();
        assertEq(outStandingTotalDebt, 10);
    }
}

        // sets block.number
        vm.roll(25000);
        CreditNFT(creditNFTAddress).updateTotalDebt();
        uint256 outStandingTotalDebt =
            CreditNFT(creditNFTAddress).getTotalOutstandingDebt();
        assertEq(outStandingTotalDebt, 10);
    }
}