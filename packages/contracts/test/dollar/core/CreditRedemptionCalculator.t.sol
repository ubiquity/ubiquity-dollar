// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../../../src/dollar/core/CreditRedemptionCalculator.sol";
import "../../helpers/LocalTestHelper.sol";

contract CreditRedemptionCalculatorTest is LocalTestHelper {
    CreditRedemptionCalculator creditCalc;

    // test users
    address user;

    function setUp() public override {
        super.setUp();

        user = address(0x01);

        creditCalc = new CreditRedemptionCalculator(manager);
    }

    function testConstructor_ShouldInitContract() public {
        assertEq(address(creditCalc.manager()), address(manager));
    }

    function testSetConstant_ShouldRevert_IfCalledNotByAdmin() public {
        vm.prank(user);
        vm.expectRevert("CreditCalculator: not admin");
        creditCalc.setConstant(2 ether);
    }

    function testSetConstant_ShouldUpdateCoef() public {
        vm.prank(admin);
        creditCalc.setConstant(2 ether);
        assertEq(creditCalc.getConstant(), 2 ether);
    }

    function testGetCreditAmount_ShouldRevert_IfDebtIsTooHigh() public {
        vm.mockCall(
            manager.dollarTokenAddress(),
            abi.encodeWithSelector(IERC20.totalSupply.selector),
            abi.encode(1)
        );
        vm.expectRevert("Credit to Dollar: DEBT_TOO_HIGH");
        creditCalc.getCreditAmount(1 ether, 10);
    }

    function testGetCreditAmount_ShouldReturnAmount() public {
        uint amount = creditCalc.getCreditAmount(1 ether, 10);
        assertEq(amount, 9999999999999999999);
    }
}
