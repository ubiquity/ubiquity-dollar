// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/console.sol";
import {DiamondTestSetup} from "../DiamondTestSetup.sol";
import {LibStaking} from "../../../src/dollar/libraries/LibStaking.sol";
import {MockERC20} from "../../../src/dollar/mocks/MockERC20.sol";

contract StakingFacetTest is DiamondTestSetup {
    MockERC20 stakeToken;

    function setUp() public override {
        super.setUp();
    }

    function testMy() public {
        assertEq(uint(1), uint(1));
    }
}
