// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../../src/dollar/core/CreditRedemptionCalculator.sol";
import "../../helpers/LocalTestHelper.sol";

contract CreditRedemptionCalculatorTest is LocalTestHelper {
    CreditRedemptionCalculator creditRedemptionCalculator;

    // test users
    address user;

    address dollarManagerAddress;

    function setUp() public {
        user = address(0x01);

        dollarManagerAddress = helpers_deployUbiquityDollarManager();
        creditRedemptionCalculator = new CreditRedemptionCalculator(
            dollarManagerAddress
        );
    }

    function testConstructor_ShouldInitContract() public {
        assertEq(
            address(creditRedemptionCalculator.manager()),
            dollarManagerAddress
        );
    }

    function testSetConstant_ShouldRevert_IfCalledNotByAdmin() public {
        vm.prank(user);
        vm.expectRevert("CreditCalc: not admin");
        creditRedemptionCalculator.setConstant(2 ether);
    }

    function testSetConstant_ShouldUpdateCoef() public {
        vm.prank(admin);
        creditRedemptionCalculator.setConstant(2 ether);
        assertEq(creditRedemptionCalculator.getConstant(), 2 ether);
    }

    function testGetCreditAmount_ShouldRevert_IfDebtIsTooHigh() public {
        vm.mockCall(
            UbiquityDollarManager(dollarManagerAddress).dollarTokenAddress(),
            abi.encodeWithSelector(IERC20.totalSupply.selector),
            abi.encode(1)
        );
        vm.expectRevert("Credit to Dollar: DEBT_TOO_HIGH");
        creditRedemptionCalculator.getCreditAmount(1 ether, 10);
    }

    function testGetCreditAmount_ShouldReturnAmount() public {
        uint amount = creditRedemptionCalculator.getCreditAmount(1 ether, 10);
        assertEq(amount, 9999999999999999999);
    }
}
