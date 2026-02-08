// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

/**
 * @notice ERC1155 Ubiquity interface
 * @notice ERC1155 with:
 * - ERC1155 minter, burner and pauser
 * - TotalSupply per id
 * - Ubiquity Manager access control
 */
interface IERC1155Ubiquity is IERC1155 {
    /**
     * @notice Creates `amount` new tokens for `to`, of token type `id`
     * @param to Address where to mint tokens
     * @param id Token type id
     * @param amount Tokens amount to mint
     * @param data Arbitrary data
     */
    function mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    /**
     * @notice Mints multiple token types for `to` address
     * @param to Address where to mint tokens
     * @param ids Array of token type ids
     * @param amounts Array of token amounts
     * @param data Arbitrary data
     */
    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    /**
     * @notice Destroys `amount` tokens of token type `id` from `account`
     *
     * Emits a `TransferSingle` event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function burn(address account, uint256 id, uint256 value) external;

    /**
     * @notice Batched version of `_burn()`
     *
     * Emits a `TransferBatch` event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;

    /// @notice Pauses all token transfers
    function pause() external;

    /// @notice Unpauses all token transfers
    function unpause() external;

    /**
     * @notice Returns total supply among all token ids
     * @return Total supply among all token ids
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Checks whether token `id` exists
     * @return Whether token `id` exists
     */
    function exists(uint256 id) external view returns (bool);

    /**
     * @notice Returns array of token ids held by the `holder`
     * @param holder Account to check tokens for
     * @return Array of tokens which `holder` has
     */
    function holderTokens(
        address holder
    ) external view returns (uint256[] memory);
}
