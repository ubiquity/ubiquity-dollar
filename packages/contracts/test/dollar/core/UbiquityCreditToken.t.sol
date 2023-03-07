// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../../../src/diamond/token/UbiquityCreditTokenForDiamond.sol";
import "../../helpers/LocalTestHelper.sol";

contract UbiquityCreditTokenTest is LocalTestHelper {
    UbiquityCreditTokenForDiamond ubiquityCreditToken;

    function setUp() public override {
        super.setUp();

        vm.prank(admin);
        ubiquityCreditToken = new UbiquityCreditTokenForDiamond(
            address(diamond)
        );
    }

    function testRaiseCapital_ShouldMintTokens() public {
        assertEq(ubiquityCreditToken.balanceOf(treasuryAddress), 0);
        vm.prank(admin);
        ubiquityCreditToken.raiseCapital(1e18);
        assertEq(ubiquityCreditToken.balanceOf(treasuryAddress), 1e18);
    }
}
