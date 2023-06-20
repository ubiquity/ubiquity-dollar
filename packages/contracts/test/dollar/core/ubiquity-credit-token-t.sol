// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../../../src/dollar/core/ubiquity-credit-token.sol";
import "../../helpers/local-test-helper.sol";

contract UbiquityCreditTokenTest is LocalTestHelper {
    UbiquityCreditToken ubiquityCreditToken;

    function setUp() public override {
        super.setUp();

        vm.prank(admin);
        ubiquityCreditToken = new UbiquityCreditToken(address(diamond));
    }

    function testRaiseCapital_ShouldMintTokens() public {
        assertEq(ubiquityCreditToken.balanceOf(treasuryAddress), 0);
        vm.prank(admin);
        ubiquityCreditToken.raiseCapital(1e18);
        assertEq(ubiquityCreditToken.balanceOf(treasuryAddress), 1e18);
    }

    function testSetManager_ShouldRevert_WhenNotAdmin() public {
        vm.prank(address(0x123abc));
        vm.expectRevert("ERC20Ubiquity: not admin");
        ubiquityCreditToken.setManager(address(0x123abc));
    }

    function testSetManager_ShouldSetManager() public {
        address newManager = address(0x123abc);
        vm.prank(admin);
        ubiquityCreditToken.setManager(newManager);
        require(ubiquityCreditToken.getManager() == newManager);
    }
}
