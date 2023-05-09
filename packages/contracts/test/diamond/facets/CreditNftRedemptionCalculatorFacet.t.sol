// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../DiamondTestSetup.sol";

contract CreditNftRedemptionCalculatorFacetTest is DiamondSetup {
    using stdStorage for StdStorage;

    CreditNft creditNFT;

    function setUp() public virtual override {
        super.setUp();
        vm.prank(admin);
        IDollar.mint(admin, 10000e18);
        uint256 admSupply = IDollar.balanceOf(admin);
        assertEq(admSupply, 10000e18);
        creditNFT = new CreditNft(address(diamond));
        vm.prank(admin);
        IManager.setCreditNftAddress(address(creditNFT));
    }

    function test_getCreditNFTAmount_revertsIfDebtTooHigh() public {
        uint256 totalSupply = IDollar.totalSupply();
        stdstore
            .target(address(creditNFT))
            .sig("_totalOutstandingDebt")
            .checked_write(totalSupply + 1);

        vm.expectRevert("CreditNFT to Dollar: DEBT_TOO_HIGH");
        ICreditNFTRedCalcFacet.getCreditNftAmount(0);
    }

    function test_getCreditNFTAmount() public {
        uint256 totalSupply = IDollar.totalSupply();
        stdstore
            .target(address(creditNFT))
            .sig("_totalOutstandingDebt")
            .checked_write(totalSupply / 2);
        assertEq(ICreditNFTRedCalcFacet.getCreditNftAmount(10000), 40000);
    }
}
