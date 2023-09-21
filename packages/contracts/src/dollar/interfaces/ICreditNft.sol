// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";

/// @notice CreditNft interface
interface ICreditNft is IERC1155Upgradeable {
    /**
     * @notice Updates debt according to current block number
     * @notice Invalidates expired CreditNfts
     * @dev Should be called prior to any state changing functions
     */
    function updateTotalDebt() external;

    /**
     * @notice Burns an `amount` of CreditNfts expiring at `expiryBlockNumber` from `creditNftOwner` balance
     * @param creditNftOwner Owner of those CreditNfts
     * @param amount Amount of tokens to burn
     * @param expiryBlockNumber Expiration block number of the CreditNfts to burn
     */
    function burnCreditNft(
        address creditNftOwner,
        uint256 amount,
        uint256 expiryBlockNumber
    ) external;

    /**
     * @notice Mint an `amount` of CreditNfts expiring at `expiryBlockNumber` for a certain `recipient`
     * @param recipient Address where to mint tokens
     * @param amount Amount of tokens to mint
     * @param expiryBlockNumber Expiration block number of the CreditNfts to mint
     */
    function mintCreditNft(
        address recipient,
        uint256 amount,
        uint256 expiryBlockNumber
    ) external;

    /// @notice Returns outstanding debt by fetching current tally and removing any expired debt
    function getTotalOutstandingDebt() external view returns (uint256);
}
