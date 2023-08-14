// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../DiamondTestSetup.sol";
import {CreditNft} from "../../../src/dollar/core/CreditNft.sol";

contract CreditNftRedemptionCalculatorFacetTest is DiamondSetup {
    CreditNft _creditNft;

    function setUp() public virtual override {
        super.setUp();
        vm.prank(admin);
        IDollar.mint(admin, 10000e18);
        uint256 admSupply = IDollar.balanceOf(admin);
        assertEq(admSupply, 10000e18);
        _creditNft = new CreditNft(address(diamond));

        vm.startPrank(admin);
        IManager.setCreditNftAddress(address(_creditNft));
        IAccessControl.grantRole(CREDIT_NFT_MANAGER_ROLE, address(this));
        IAccessControl.grantRole(GOVERNANCE_TOKEN_MINTER_ROLE, address(this));
        vm.stopPrank();
    }

    function test_getCreditNftAmount_revertsIfDebtTooHigh() public {
        _creditNft.mintCreditNft(user1, 100000 ether, 1000);
        vm.expectRevert("CreditNft to Dollar: DEBT_TOO_HIGH");
        ICreditNftRedemptionCalculationFacet.getCreditNftAmount(0);
    }

    function test_getCreditNftAmount() public {
        _creditNft.mintCreditNft(user1, 5000 ether, 10);
        assertEq(
            ICreditNftRedemptionCalculationFacet.getCreditNftAmount(10000),
            40000
        );
    }
}
