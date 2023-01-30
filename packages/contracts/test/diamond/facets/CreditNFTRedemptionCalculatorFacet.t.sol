// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../DiamondTestSetup.sol";
import "../../../src/dollar/mocks/MockCreditNFT.sol";

contract CreditNFTRedemptionCalculatorFacetTest is DiamondSetup {
    MockCreditNFT _creditNFT;

    function setUp() public virtual override {
        super.setUp();
        vm.prank(admin);
        IDollarFacet.mint(admin, 10000e18);
        uint256 admSupply = IDollarFacet.balanceOf(admin);
        assertEq(admSupply, 10000e18);
        _creditNFT = new MockCreditNFT(100);
        vm.prank(admin);
        IManager.setCreditNFTAddress(address(_creditNFT));
    }

    function test_getCreditNFTAmount_revertsIfDebtTooHigh() public {
        uint256 totalSupply = IDollarFacet.totalSupply();
        MockCreditNFT(IManager.creditNFTAddress()).setTotalOutstandingDebt(
            totalSupply + 1
        );

        vm.expectRevert("CreditNFT to Dollar: DEBT_TOO_HIGH");
        ICreditNFTRedCalcFacet.getCreditNFTAmount(0);
    }

    function test_getCreditNFTAmount() public {
        uint256 totalSupply = IDollarFacet.totalSupply();
        MockCreditNFT(IManager.creditNFTAddress()).setTotalOutstandingDebt(
            totalSupply / 2
        );
        assertEq(ICreditNFTRedCalcFacet.getCreditNFTAmount(10000), 40000);
    }
}
