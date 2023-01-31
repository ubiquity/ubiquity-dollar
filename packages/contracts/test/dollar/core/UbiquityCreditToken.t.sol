// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../../src/dollar/core/UbiquityCreditToken.sol";
import "../../helpers/LocalTestHelper.sol";

contract UbiquityCreditTokenTest is LocalTestHelper {
    UbiquityCreditToken creditToken;

    address dollarManagerAddress;

    function setUp() public {
        dollarManagerAddress = helpers_deployUbiquityDollarManager();
        vm.prank(admin);
        creditToken = new UbiquityCreditToken(dollarManagerAddress);
    }

    function testRaiseCapital_ShouldMintTokens() public {
        assertEq(creditToken.balanceOf(treasuryAddress), 0);
        vm.prank(admin);
        creditToken.raiseCapital(1e18);
        assertEq(creditToken.balanceOf(treasuryAddress), 1e18);
    }
}
