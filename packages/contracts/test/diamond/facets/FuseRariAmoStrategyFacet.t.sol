// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/console.sol";
import {DiamondTestSetup} from "../DiamondTestSetup.sol";
import {MockERC20} from "../../../src/dollar/mocks/MockERC20.sol";

contract FuseRariAmoStrategyTest is DiamondTestSetup {
    function setUp() public override {
        MockERC20 collateralToken;

        super.setUp();

        vm.startPrank(admin);
        // init collateral token
        collateralToken = new MockERC20("COLLATERAL", "CLT", 18);

        vm.stopPrank();
    }
}
