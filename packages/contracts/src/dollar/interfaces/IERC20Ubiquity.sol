// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

/**
 * @notice Interface for ERC20Ubiquity contract
 */
interface IERC20Ubiquity is IERC20, IERC20Permit {
    // ----------- Events -----------

    /// @notice Emitted on tokens minting
    event Minting(
        address indexed _to,
        address indexed _minter,
        uint256 _amount
    );

    /// @notice Emitted on tokens burning
    event Burning(address indexed _burned, uint256 _amount);

    /**
     * @notice Burns tokens from `msg.sender`
     * @param amount Amount of tokens to burn
     */
    function burn(uint256 amount) external;

    /**
     * @notice Burns tokens from the `account` address
     * @param account Address to burn tokens from
     * @param amount Amount of tokens to burn
     */
    function burnFrom(address account, uint256 amount) external;

    /**
     * @notice Mints tokens to the `account` address
     * @param account Address to mint tokens to
     * @param amount Amount of tokens to mint
     */
    function mint(address account, uint256 amount) external;
}
