// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../../../src/dollar/core/DebtClock.sol";

import "../../helpers/LocalTestHelper.sol";

contract DebtClockTest is LocalTestHelper {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    UbiquityDollarManager manager;
    DebtClock debtClock;

    function setUp() public {
        manager = new UbiquityDollarManager(address(this));
        debtClock = new DebtClock(manager, uint256(50).fromUInt(), uint256(3).fromUInt());
    }

    function testConstructor() public {
        require(debtClock.manager() == manager);
        require(debtClock.rateStartBlock() == block.number);
        require(debtClock.rateStartValue() == uint256(50).fromUInt());
        require(debtClock.ratePerBlock() == uint256(3).fromUInt());
    }

    function testSetRatePerBlock() public {
        debtClock.setRatePerBlock(uint256(1 ether).fromUInt());

        require(debtClock.rateStartBlock() == block.number);
    }

}
