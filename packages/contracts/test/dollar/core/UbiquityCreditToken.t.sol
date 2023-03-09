// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../../../src/dollar/core/UbiquityCreditToken.sol";
import "../../helpers/LocalTestHelper.sol";

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

    function testSetDiamond_ShouldRevert_WhenNotAdmin() public {
        vm.prank(address(0x123abc));
        vm.expectRevert("ERC20Ubiquity: not admin");
        ubiquityCreditToken.setDiamond(address(0x123abc));
    }

    function testSetDiamond_ShouldSetDiamond() public {
        address newDiamond = address(0x123abc);
        vm.prank(admin);
        ubiquityCreditToken.setDiamond(newDiamond);
        require(ubiquityCreditToken.getDiamond() == newDiamond);
    }
}
