// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../DiamondTestSetup.sol";
import {CreditNft} from "../../../src/dollar/core/CreditNft.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CreditRedemptionCalculatorFacetTest is DiamondSetup {
    CreditNft _creditNft;

    function setUp() public virtual override {
        super.setUp();
        vm.prank(admin);
        IDollar.mint(admin, 10000e18);
        uint256 admSupply = IDollar.balanceOf(admin);
        assertEq(admSupply, 10000e18);

        _creditNft = new CreditNft(address(diamond));
        vm.startPrank(admin);
        IAccessControl.grantRole(CREDIT_NFT_MANAGER_ROLE, address(this));
        _creditNft.mintCreditNft(user1, 100, 10);
        IManager.setCreditNftAddress(address(_creditNft));
        vm.stopPrank();
    }

    function testSetConstant_ShouldRevert_IfCalledNotByAdmin() public {
        vm.prank(user1);
        vm.expectRevert("CreditCalc: not admin");
        ICreditRedemptionCalculationFacet.setConstant(2 ether);
    }

    function testSetConstant_ShouldUpdateCoef() public {
        vm.prank(admin);
        ICreditRedemptionCalculationFacet.setConstant(2 ether);
        assertEq(ICreditRedemptionCalculationFacet.getConstant(), 2 ether);
    }

    function testGetCreditAmount_ShouldRevert_IfDebtIsTooHigh() public {
        vm.mockCall(
            IManager.dollarTokenAddress(),
            abi.encodeWithSelector(IERC20.totalSupply.selector),
            abi.encode(1)
        );
        vm.expectRevert("Credit to Dollar: DEBT_TOO_HIGH");
        ICreditRedemptionCalculationFacet.getCreditAmount(1 ether, 10);
    }

    function testGetCreditAmount_ShouldReturnAmount() public {
        uint256 amount = ICreditRedemptionCalculationFacet.getCreditAmount(
            1 ether,
            10
        );
        assertEq(amount, 9999999999999999999);
    }
}
