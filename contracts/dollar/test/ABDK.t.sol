// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../src/ABDKTest.sol";

contract ABDK is Test {
    uint256 maxABDK =
        0xffffffffffffffffffffffffffff800000000000000000000000000000000000;
    ABDKTest abdkTest = new ABDKTest();

    function setUp() public {}

    function testMaxuint128() public {
        // should return max uint128 at maximum
        uint256 max = abdkTest.max();
        assertEq(max, maxABDK);
    }
}
