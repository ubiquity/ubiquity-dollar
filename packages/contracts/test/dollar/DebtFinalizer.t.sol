// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../../src/dollar/libraries/LibDebtFinalizer.sol";
import "../../src/dollar/mocks/MockERC20.sol";

/// @title Test contract wrapping LibDebtFinalizer
contract DebtFinalizerWrapper {
    using LibDebtFinalizer for LibDebtFinalizer.DebtStorage;

    function registerDebt(address investor, uint256 totalDebt, uint256 startBlock, uint256 endBlock) external {
        LibDebtFinalizer.debtStorage().registerDebt(investor, totalDebt, startBlock, endBlock);
    }

    function calculateVested(address investor, uint256 currentBlock) external view returns (uint256) {
        return LibDebtFinalizer.debtStorage().calculateVested(investor, currentBlock);
    }

    function finalizeInvestor(address investor, uint256 currentBlock) external returns (uint256) {
        return LibDebtFinalizer.debtStorage().finalizeInvestor(investor, currentBlock);
    }

    function batchFinalize(uint256 currentBlock) external returns (uint256) {
        return LibDebtFinalizer.debtStorage().batchFinalize(currentBlock);
    }

    function handleWithdrawnStake(address investor, uint256 withdrawnAmount) external {
        LibDebtFinalizer.debtStorage().handleWithdrawnStake(investor, withdrawnAmount);
    }
}

contract DebtFinalizerTest is Test {
    DebtFinalizerWrapper wrapper;
    MockERC20 governanceToken;
    address investor1 = address(0x1);
    address investor2 = address(0x2);

    function setUp() public {
        governanceToken = new MockERC20("UBQ", "Ubiquity Governance", 18);
        wrapper = new DebtFinalizerWrapper();
        governanceToken.mint(address(wrapper), 1_000_000e18);
    }

    function testRegisterDebt() public {
        wrapper.registerDebt(investor1, 100_000e18, 100, 1000);
        uint256 vested = wrapper.calculateVested(investor1, 550);
        assertEq(vested, 45_000e18); // 50% through vesting
    }

    function testFullVesting() public {
        wrapper.registerDebt(investor1, 100_000e18, 100, 1000);
        uint256 vested = wrapper.calculateVested(investor1, 1000);
        assertEq(vested, 100_000e18);
    }

    function testBeforeVestingStarts() public {
        wrapper.registerDebt(investor1, 100_000e18, 100, 1000);
        uint256 vested = wrapper.calculateVested(investor1, 50);
        assertEq(vested, 0);
    }

    function testFinalizeInvestor() public {
        wrapper.registerDebt(investor1, 100_000e18, 100, 1000);
        uint256 distributed = wrapper.finalizeInvestor(investor1, 1000);
        assertEq(distributed, 100_000e18);
        assertEq(governanceToken.balanceOf(investor1), 100_000e18);
    }

    function testBatchFinalize() public {
        wrapper.registerDebt(investor1, 100_000e18, 100, 1000);
        wrapper.registerDebt(investor2, 200_000e18, 100, 1000);
        uint256 total = wrapper.batchFinalize(1000);
        assertEq(total, 300_000e18);
    }

    function testHandleWithdrawnStake() public {
        wrapper.registerDebt(investor1, 100_000e18, 100, 1000);
        wrapper.handleWithdrawnStake(investor1, 30_000e18);
        uint256 vested = wrapper.calculateVested(investor1, 1000);
        assertEq(vested, 70_000e18);
    }

    function testRevertDoubleFinalize() public {
        wrapper.registerDebt(investor1, 100_000e18, 100, 1000);
        wrapper.finalizeInvestor(investor1, 1000);
        vm.expectRevert("Already finalized");
        wrapper.finalizeInvestor(investor1, 1000);
    }
}
