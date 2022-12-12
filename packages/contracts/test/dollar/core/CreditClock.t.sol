// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../../../src/dollar/core/CreditClock.sol";

import "../../helpers/LocalTestHelper.sol";

contract CreditClockTest is LocalTestHelper {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    UbiquityDollarManager manager;
    CreditClock creditClock;

    function setUp() public {
        manager = new UbiquityDollarManager(address(this));
        creditClock = new CreditClock(manager, uint256(50).fromUInt(), uint256(3).fromUInt());
    }

    function testConstructor() public view {
        require(creditClock.rateStartBlock() == block.number);
        require(creditClock.rateStartValue() == uint256(50).fromUInt());
        require(creditClock.ratePerBlock() == uint256(3).fromUInt());
    }

    function testSetRatePerBlock() public {
        creditClock.setRatePerBlock(uint256(1).fromUInt());

        require(creditClock.rateStartBlock() == block.number);
        require(creditClock.rateStartValue() == uint256(50).fromUInt());
        require(creditClock.ratePerBlock() == uint256(1).fromUInt());
    }

    function testCalculateRate() public view {
        require(creditClock.calculateRate(uint256(8000).fromUInt(), uint256(3).fromUInt(), 0).toUInt() == 8000);
        require(creditClock.calculateRate(uint256(8000).fromUInt(), uint256(3).fromUInt(), 1).toUInt() == 2000);
        require(creditClock.calculateRate(uint256(8000).fromUInt(), uint256(3).fromUInt(), 2).toUInt() == 500);
        require(creditClock.calculateRate(uint256(8000).fromUInt(), uint256(3).fromUInt(), 3).toUInt() == 125);

        require(creditClock.calculateRate(uint256(16000).fromUInt(), uint256(3).fromUInt(), 0).toUInt() == 16000);
        require(creditClock.calculateRate(uint256(16000).fromUInt(), uint256(3).fromUInt(), 1).toUInt() == 4000);
        require(creditClock.calculateRate(uint256(16000).fromUInt(), uint256(3).fromUInt(), 2).toUInt() == 1000);
        require(creditClock.calculateRate(uint256(16000).fromUInt(), uint256(3).fromUInt(), 3).toUInt() == 250);

        require(creditClock.calculateRate(uint256(2000).fromUInt(), uint256(9).fromUInt(), 0).toUInt() == 2000);
        require(creditClock.calculateRate(uint256(2000).fromUInt(), uint256(9).fromUInt(), 1).toUInt() == 200);
        require(creditClock.calculateRate(uint256(2000).fromUInt(), uint256(9).fromUInt(), 2).toUInt() == 20);
        require(creditClock.calculateRate(uint256(2000).fromUInt(), uint256(9).fromUInt(), 3).toUInt() == 2);
    }

    function testControlGetRateOldBlock() public view {
        creditClock.getRate(block.number);
    }

    function testFailGetRateOldBlock() public view {
        creditClock.getRate(block.number - 1);
    }

    function testGetRate() public view {
        require(creditClock.getRate(0) == uint256(50).fromUInt());
        require(creditClock.getRate(block.number) == uint256(50).fromUInt());
    }

}
