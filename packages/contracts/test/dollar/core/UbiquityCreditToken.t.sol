// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../../src/dollar/core/UbiquityCreditToken.sol";
import "../../helpers/LocalTestHelper.sol";

contract UbiquityCreditTokenTest is LocalTestHelper {
    UbiquityCreditToken ubiquityCreditToken;

    function setUp() public override {
        super.setUp();

        vm.prank(admin);
        ubiquityCreditToken = new UbiquityCreditToken(manager);
    }

    function testRaiseCapital_ShouldMintTokens() public {
        assertEq(ubiquityCreditToken.balanceOf(treasuryAddress), 0);
        vm.prank(admin);
        ubiquityCreditToken.raiseCapital(1e18);
        assertEq(ubiquityCreditToken.balanceOf(treasuryAddress), 1e18);
    }
}
