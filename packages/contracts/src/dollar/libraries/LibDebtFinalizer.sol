// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title LibDebtFinalizer - Finalize Pre-Seed/Seed Investor Debt UBQ Distribution
library LibDebtFinalizer {
    struct InvestorDebt {
        address investor;
        uint256 totalDebt;
        uint256 paidAmount;
        uint256 startBlock;
        uint256 endBlock;
        bool finalized;
    }

    struct DebtStorage {
        mapping(address => InvestorDebt) investors;
        address[] investorList;
        address governanceToken;
        uint256 totalDebtRemaining;
        uint256 vestingCliffBlock;
    }

    bytes32 constant STORAGE_POSITION = keccak256("ubiquity.debt.finalizer");

    function debtStorage() internal pure returns (DebtStorage storage ds) {
        bytes32 position = STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event DebtFinalized(address indexed investor, uint256 amount, uint256 blockNumber);
    event BatchFinalized(uint256 count, uint256 totalAmount);

    /// @notice Register an investor debt
    function registerDebt(
        address investor,
        uint256 totalDebt,
        uint256 startBlock,
        uint256 endBlock
    ) internal {
        DebtStorage storage ds = debtStorage();
        require(!ds.investors[investor].finalized, "Already finalized");
        require(totalDebt > 0, "Debt must be > 0");

        ds.investors[investor] = InvestorDebt({
            investor: investor,
            totalDebt: totalDebt,
            paidAmount: 0,
            startBlock: startBlock,
            endBlock: endBlock,
            finalized: false
        });
        ds.investorList.push(investor);
        ds.totalDebtRemaining += totalDebt;
    }

    /// @notice Calculate vested amount for an investor at current block
    function calculateVested(address investor, uint256 currentBlock) internal view returns (uint256) {
        DebtStorage storage ds = debtStorage();
        InvestorDebt storage debt = ds.investors[investor];
        require(debt.totalDebt > 0, "No debt registered");

        if (currentBlock < debt.startBlock) return 0;
        if (currentBlock >= debt.endBlock) return debt.totalDebt - debt.paidAmount;

        uint256 elapsed = currentBlock - debt.startBlock;
        uint256 duration = debt.endBlock - debt.startBlock;
        uint256 vestedTotal = (debt.totalDebt * elapsed) / duration;
        
        return vestedTotal > debt.paidAmount ? vestedTotal - debt.paidAmount : 0;
    }

    /// @notice Finalize debt for a single investor
    function finalizeInvestor(address investor, uint256 currentBlock) internal returns (uint256) {
        DebtStorage storage ds = debtStorage();
        InvestorDebt storage debt = ds.investors[investor];
        require(!debt.finalized, "Already finalized");

        uint256 amount = calculateVested(investor, currentBlock);
        require(amount > 0, "Nothing to finalize");

        debt.paidAmount += amount;
        debt.finalized = true;
        ds.totalDebtRemaining -= amount;

        IERC20(ds.governanceToken).transfer(investor, amount);

        emit DebtFinalized(investor, amount, currentBlock);
        return amount;
    }

    /// @notice Batch finalize all investors
    function batchFinalize(uint256 currentBlock) internal returns (uint256 totalDistributed) {
        DebtStorage storage ds = debtStorage();
        uint256 count;

        for (uint256 i = 0; i < ds.investorList.length; i++) {
            address investor = ds.investorList[i];
            if (!ds.investors[investor].finalized) {
                uint256 amount = calculateVested(investor, currentBlock);
                if (amount > 0) {
                    ds.investors[investor].paidAmount += amount;
                    ds.investors[investor].finalized = true;
                    ds.totalDebtRemaining -= amount;
                    IERC20(ds.governanceToken).transfer(investor, amount);
                    totalDistributed += amount;
                    count++;
                    emit DebtFinalized(investor, amount, currentBlock);
                }
            }
        }

        emit BatchFinalized(count, totalDistributed);
    }

    /// @notice Handle withdrawn stakes - reduce remaining debt
    function handleWithdrawnStake(address investor, uint256 withdrawnAmount) internal {
        DebtStorage storage ds = debtStorage();
        InvestorDebt storage debt = ds.investors[investor];
        require(debt.totalDebt > 0, "No debt registered");
        require(!debt.finalized, "Already finalized");

        uint256 remaining = debt.totalDebt - debt.paidAmount;
        uint256 reduction = withdrawnAmount > remaining ? remaining : withdrawnAmount;

        debt.totalDebt -= reduction;
        ds.totalDebtRemaining -= reduction;
    }
}
