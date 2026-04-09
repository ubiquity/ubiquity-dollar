// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @notice Interface for the LQTY token (Liquity governance token)
interface ILQTY {
    /// @notice Returns the total supply of LQTY
    function totalSupply() external view returns (uint256);

    /// @notice Returns the balance of an account
    function balanceOf(address account) external view returns (uint256);

    /// @notice Transfers LQTY tokens
    function transfer(address recipient, uint256 amount) external returns (bool);

    /// @notice Approves spending of LQTY tokens
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice Returns the allowance
    function allowance(address owner, address spender) external view returns (uint256);

    /// @notice Transfers LQTY tokens from sender to recipient
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
