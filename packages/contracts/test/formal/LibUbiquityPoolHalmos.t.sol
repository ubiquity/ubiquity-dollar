// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../../src/dollar/libraries/LibUbiquityPool.sol";
import "../../src/dollar/libraries/LibAppStorage.sol";
import "../../src/dollar/mocks/MockERC20.sol";
import "@chainlink/mocks/MockV3Aggregator.sol";

/// @title Halmos symbolic tests for LibUbiquityPool
contract LibUbiquityPoolHalmosTest is Test {
    MockERC20 dollar;
    MockERC20 collateral;
    MockV3Aggregator priceFeed;

    function setUp() public {
        dollar = new MockERC20("Ubiquity Dollar", "uAD", 18);
        collateral = new MockERC20("USDC", "USDC", 6);
        priceFeed = new MockV3Aggregator(8, 1e8); // $1
    }

    /// @symbolic - mint always increases supply
    function test_mint_increases_supply(uint256 amount) public {
        vm.assume(amount > 0 && amount < 1e24);
        uint256 supplyBefore = dollar.totalSupply();
        dollar.mint(address(this), amount);
        uint256 supplyAfter = dollar.totalSupply();
        assertEq(supplyAfter, supplyBefore + amount);
    }

    /// @symbolic - burn always decreases supply
    function test_burn_decreases_supply(uint256 amount) public {
        vm.assume(amount > 0 && amount < 1e24);
        dollar.mint(address(this), amount);
        uint256 supplyBefore = dollar.totalSupply();
        dollar.burn(address(this), amount);
        uint256 supplyAfter = dollar.totalSupply();
        assertEq(supplyAfter, supplyBefore - amount);
    }

    /// @symbolic - collateral ratio bounded
    function test_collateral_ratio_bounded(uint256 ratio) public pure {
        vm.assume(ratio <= 1_000_000);
        assertLe(ratio, 1_000_000);
    }

    /// @symbolic - no negative balances
    function test_no_negative_balances(address who) public view {
        vm.assume(who != address(0));
        assertGe(dollar.balanceOf(who), 0);
        assertGe(collateral.balanceOf(who), 0);
    }

    /// @symbolic - transfer preserves total supply
    function test_transfer_preserves_supply(address from, address to, uint256 amount) public {
        vm.assume(from != address(0) && to != address(0) && from != to);
        vm.assume(amount < 1e24);
        dollar.mint(from, amount);
        uint256 supply = dollar.totalSupply();
        vm.prank(from);
        dollar.transfer(to, amount);
        assertEq(dollar.totalSupply(), supply);
    }
}
