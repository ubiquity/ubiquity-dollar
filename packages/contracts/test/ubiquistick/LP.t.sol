// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "forge-std/Test.sol";

import "../../src/ubiquistick/LP.sol";

contract LPTest is Test {
    LP lp;

    // test users
    address owner;

    function setUp() public {
        owner = address(0x01);

        vm.prank(owner);
        lp = new LP("LP", "LP");
    }

    function testMint_ShouldMintTokens() public {
        assertEq(lp.balanceOf(owner), 0);

        vm.prank(owner);
        lp.mint(1 ether);

        assertEq(lp.balanceOf(owner), 1 ether);
    }
}
