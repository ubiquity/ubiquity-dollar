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

    function testConstructor() public view {
        require(debtClock.manager() == manager);
        require(debtClock.rateStartBlock() == block.number);
        require(debtClock.rateStartValue() == uint256(50).fromUInt());
        require(debtClock.ratePerBlock() == uint256(3).fromUInt());
    }

    function testSetRatePerBlock() public {
        debtClock.setRatePerBlock(uint256(1).fromUInt());

        require(debtClock.rateStartBlock() == block.number);
        require(debtClock.rateStartValue() == uint256(50).fromUInt());
        require(debtClock.ratePerBlock() == uint256(1).fromUInt());
    }

    function testCalculateRate() public view {
        require(debtClock.calculateRate(uint256(8000).fromUInt(), uint256(3).fromUInt(), 0).toUInt() == 8000);
        require(debtClock.calculateRate(uint256(8000).fromUInt(), uint256(3).fromUInt(), 1).toUInt() == 2000);
        require(debtClock.calculateRate(uint256(8000).fromUInt(), uint256(3).fromUInt(), 2).toUInt() == 500);
        require(debtClock.calculateRate(uint256(8000).fromUInt(), uint256(3).fromUInt(), 3).toUInt() == 125);

        require(debtClock.calculateRate(uint256(16000).fromUInt(), uint256(3).fromUInt(), 0).toUInt() == 16000);
        require(debtClock.calculateRate(uint256(16000).fromUInt(), uint256(3).fromUInt(), 1).toUInt() == 4000);
        require(debtClock.calculateRate(uint256(16000).fromUInt(), uint256(3).fromUInt(), 2).toUInt() == 1000);
        require(debtClock.calculateRate(uint256(16000).fromUInt(), uint256(3).fromUInt(), 3).toUInt() == 250);
    }

    function testGetRate() public {
        debtClock.setRatePerBlock(uint256(1).fromUInt());
        require(debtClock.getRate(0) == uint256(50).fromUInt());
        require(debtClock.getRate(block.number) == uint256(50).fromUInt());
    }

}
