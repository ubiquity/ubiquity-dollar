// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {CreditClockFacet} from "../../../src/dollar/facets/CreditClockFacet.sol";
import "abdk/ABDKMathQuad.sol";
import "../DiamondTestSetup.sol";

contract CreditClockFacetTest is DiamondTestSetup {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    function setUp() public override {
        super.setUp();
    }

    function testSetManager_ShouldRevert_WhenNotAdmin() public {
        vm.prank(address(0x123abc));
        vm.expectRevert("Manager: Caller is not admin");
        creditClockFacet.setManager(address(0x123abc));
    }

    function testSetManager_ShouldSetDiamond() public {
        address newDiamond = address(0x123abc);
        vm.prank(admin);
        creditClockFacet.setManager(newDiamond);
        require(creditClockFacet.getManager() == newDiamond);
    }

    function testGetManager_ShouldGet() public view {
        creditClockFacet.getManager();
    }

    function testSetRatePerBlock_ShouldRevert_WhenNotAdmin() public {
        vm.prank(address(0x123abc));
        vm.expectRevert("Manager: Caller is not admin");
        creditClockFacet.setRatePerBlock(uint256(1).fromUInt());
    }

    function testSetRatePerBlock_Default() public {
        vm.prank(admin);
        creditClockFacet.setRatePerBlock(uint256(0).fromUInt());
    }

    function testGetRate_ShouldRevert_WhenBlockIsInThePast() public {
        vm.roll(block.number + 10);
        vm.expectRevert("CreditClock: block number must not be in the past.");
        creditClockFacet.getRate(block.number - 1);
    }
}
