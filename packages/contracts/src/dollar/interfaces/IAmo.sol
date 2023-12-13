// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;
pragma experimental ABIEncoderV2;

/// @title IAmo Interface
/// @notice Interface for the AMO (Algorithmic Monetary Operations) contract.
interface IAmo {
    /// @notice Retrieves the dollar value balances of UAD and collateral.
    /// @dev This function provides the current dollar value of UAD and collateral held by an AMO.
    /// @return uadValE18 The dollar value of UAD held, scaled to 18 decimal places.
    /// @return collatValE18 The dollar value of collateral held, scaled to 18 decimal places.
    function dollarBalances()
        external
        view
        returns (uint256 uadValE18, uint256 collatValE18);
}
