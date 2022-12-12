// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../../../src/dollar/core/DebtClock.sol";

import "../../helpers/LocalTestHelper.sol";

contract DebtClockTest is LocalTestHelper {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    DebtClock debtClock;

    function setUp() public {
        debtClock = new DebtClock(address(this));
    }

    function testTest() public {
        require(true);
    }

}
