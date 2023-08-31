// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {CreditClockFacet} from "../../../src/dollar/facets/CreditClockFacet.sol";
import "abdk/ABDKMathQuad.sol";
import "../../helpers/LocalTestHelper.sol";

contract CreditClockFacetTest is LocalTestHelper {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    CreditClockFacet creditClock;

    bytes16 private immutable one = uint256(1).fromUInt();

    event SetRatePerBlock(
        uint256 rateStartBlock,
        bytes16 rateStartValue,
        bytes16 ratePerBlock
    );

    function setUp() public override {
        super.setUp();
        creditClock = new CreditClockFacet();
    }

    function testSetManager_ShouldRevert_WhenNotAdmin() public {
        vm.prank(address(0x123abc));
        vm.expectRevert("Manager: Caller is not admin");
        creditClock.setManager(address(0x123abc));
    }

    function testSetRatePerBlock_ShouldRevert_WhenNotAdmin() public {
        vm.prank(address(0x123abc));
        vm.expectRevert("Manager: Caller is not admin");
        creditClock.setRatePerBlock(uint256(1).fromUInt());
    }

    function testGetRate_ShouldRevert_WhenBlockIsInThePast() public {
        vm.roll(block.number + 10);
        vm.expectRevert("CreditClock: block number must not be in the past.");
        creditClock.getRate(block.number - 1);
    }

    /// @dev Calculates b raised to the power of n.
    /// @param b ABDKMathQuad
    /// @param n ABDKMathQuad
    /// @return ABDKMathQuad b ^ n
    function pow(bytes16 b, bytes16 n) private pure returns (bytes16) {
        // b ^ n == 2^(n*log²(b))
        return n.mul(b.log_2()).pow_2();
    }

    /// @dev Calculate rateStartValue * ( 1 / ( (1 + ratePerBlock) ^ blockDelta) ) )
    /// @param _rateStartValue ABDKMathQuad The initial value of the rate.
    /// @param _ratePerBlock ABDKMathQuad The rate per block.
    /// @param blockDelta How many blocks after the rate was set.
    /// @return rate ABDKMathQuad The rate calculated.
    function calculateRate(
        bytes16 _rateStartValue,
        bytes16 _ratePerBlock,
        uint256 blockDelta
    ) public view returns (bytes16 rate) {
        rate = _rateStartValue.mul(
            one.div(pow(one.add(_ratePerBlock), (blockDelta).fromUInt()))
        );
    }
}
