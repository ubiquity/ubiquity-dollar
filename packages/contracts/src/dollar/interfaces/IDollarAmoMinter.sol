// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @notice AMO minter interface
/// @dev AMO minter can borrow collateral from the Ubiquity Pool to make some yield
interface IDollarAmoMinter {
    /// @notice Returns collateral Dollar balance
    /// @return Collateral Dollar balance
    function collateralDollarBalance() external view returns (uint256);

    /// @notice Returns collateral index (from the Ubiquity Pool) for which AMO minter is responsible
    /// @return Collateral token index
    function collateralIndex() external view returns (uint256);
}
