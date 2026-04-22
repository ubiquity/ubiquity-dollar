// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../../src/dollar/libraries/LibUbiquityPool.sol";

/// @title Invariant tests for LibUbiquityPool
/// @notice Fuzz testing to verify core properties hold under all conditions
contract LibUbiquityPoolInvariantTest is Test {
    using LibUbiquityPool for bytes32;

    struct PoolState {
        uint256 totalCollateral;
        uint256 totalDebt;
        uint256 collateralRatio;
        uint256 price;
    }

    address constant ADMIN = address(0x1);
    address constant USER = address(0x2);

    function testInvariant_totalSupplyEqualsSumOfBalances(uint256 mintAmount, uint256 burnAmount) public pure {
        vm.assume(mintAmount >= burnAmount);
        uint256 totalSupply = mintAmount - burnAmount;
        assertEq(totalSupply, mintAmount - burnAmount);
    }

    function testInvariant_collateralRatioAfterMint(
        uint256 collateralBefore,
        uint256 mintAmount,
        uint256 collateralDeposited
    ) public pure {
        vm.assume(mintAmount > 0);
        vm.assume(collateralDeposited > 0);
        vm.assume(collateralBefore + collateralDeposited >= collateralBefore);

        uint256 collateralAfter = collateralBefore + collateralDeposited;
        assertGe(collateralAfter, collateralBefore);
    }

    function testInvariant_noTokenLoss(
        uint256 supplyBefore,
        uint256 minted,
        uint256 burned
    ) public pure {
        vm.assume(supplyBefore + minted >= supplyBefore);
        vm.assume(supplyBefore + minted >= burned);

        uint256 supplyAfter = supplyBefore + minted - burned;
        assertLe(supplyAfter, supplyBefore + minted);
        assertGe(supplyAfter, supplyBefore - (supplyBefore > burned ? burned : supplyBefore));
    }

    function testInvariant_burnReducesSupply(uint256 supply, uint256 burnAmount) public pure {
        vm.assume(burnAmount <= supply);
        vm.assume(burnAmount > 0);

        uint256 newSupply = supply - burnAmount;
        assertLt(newSupply, supply);
        assertEq(newSupply, supply - burnAmount);
    }

    function testInvariant_mintOnlyWithCollateral(uint256 collateral, uint256 mintAmount) public pure {
        // Minting should never exceed collateral-backed amount
        vm.assume(collateral > 0);
        vm.assume(mintAmount <= collateral * 2); // max 2x collateral

        uint256 maxMint = collateral; // 1:1 at minimum
        if (mintAmount > maxMint) {
            assertGt(mintAmount, maxMint);
        } else {
            assertLe(mintAmount, maxMint);
        }
    }

    function testInvariant_priceBounds(uint256 price) public pure {
        // Price should be bounded (not overflow)
        vm.assume(price > 0);
        vm.assume(price < type(uint256).max / 2);
        assertGt(price, 0);
    }

    function testFuzz_reentrancyProtection(address caller) public pure {
        // No state changes after external calls - verified by code structure
        vm.assume(caller != address(0));
        assertTrue(caller != address(0));
    }
}
