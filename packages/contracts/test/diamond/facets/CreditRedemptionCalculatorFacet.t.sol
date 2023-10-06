// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../DiamondTestSetup.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CreditRedemptionCalculatorFacetTest is DiamondTestSetup {
    function setUp() public virtual override {
        super.setUp();
        vm.prank(admin);
        dollarToken.mint(admin, 10000e18);
        uint256 admSupply = dollarToken.balanceOf(admin);
        assertEq(admSupply, 10000e18);

        vm.startPrank(admin);
        accessControlFacet.grantRole(CREDIT_NFT_MANAGER_ROLE, address(this));
        creditNft.mintCreditNft(user1, 100, 10);
        managerFacet.setCreditNftAddress(address(creditNft));
        vm.stopPrank();
    }

    function testSetConstant_ShouldRevert_IfCalledNotByAdmin() public {
        vm.prank(user1);
        vm.expectRevert("CreditCalc: not admin");
        creditRedemptionCalculationFacet.setConstant(2 ether);
    }

    function testSetConstant_ShouldUpdateCoef() public {
        vm.prank(admin);
        creditRedemptionCalculationFacet.setConstant(2 ether);
        assertEq(creditRedemptionCalculationFacet.getConstant(), 2 ether);
    }

    function testGetCreditAmount_ShouldRevert_IfDebtIsTooHigh() public {
        vm.mockCall(
            managerFacet.dollarTokenAddress(),
            abi.encodeWithSelector(IERC20.totalSupply.selector),
            abi.encode(1)
        );
        vm.expectRevert("Credit to Dollar: DEBT_TOO_HIGH");
        creditRedemptionCalculationFacet.getCreditAmount(1 ether, 10);
    }

    function testGetCreditAmount_ShouldReturnAmount() public {
        uint256 amount = creditRedemptionCalculationFacet.getCreditAmount(
            1 ether,
            10
        );
        assertEq(amount, 9999999999999999999);
    }
}
