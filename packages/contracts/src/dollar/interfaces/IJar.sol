// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice IJar interface
interface IJar is IERC20 {
    /// @notice Transfers insurance to controller
    function claimInsurance() external; // NOTE: Only yDelegatedVault implements this

    /// @notice Deposits the whole user balance
    function depositAll() external;

    /// @notice Deposits a specified amount of tokens
    function deposit(uint256) external;

    /// @notice Withdraws all tokens
    function withdrawAll() external;

    /// @notice Withdraws a specified amount of tokens
    function withdraw(uint256) external;

    /// @notice Run strategy
    function earn() external;

    /// @notice Returns token address
    function token() external view returns (address);

    /// @notice Returns reward amount
    function reward() external view returns (address);

    /// @notice Returns ratio
    function getRatio() external view returns (uint256);

    /// @notice Returns token balance
    function balance() external view returns (uint256);

    /// @notice Returns token decimals
    function decimals() external view returns (uint8);
}
