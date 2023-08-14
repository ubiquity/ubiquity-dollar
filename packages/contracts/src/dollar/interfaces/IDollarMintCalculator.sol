// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/**
 * @notice Interface for calculating amount of Dollars to be minted
 * @notice When Dollar price > 1$ then any user can call `mintClaimableDollars()` to mint Dollars
 * in order to move Dollar token to 1$ peg. The amount of Dollars to be minted is calculated
 * using this formula `(TWAP_PRICE - 1) * DOLLAR_TOTAL_SUPPLY`.
 *
 * @notice Example:
 * 1. Dollar price (i.e. TWAP price): 1.1$, Dollar total supply: 10_000
 * 2. When `mintClaimableDollars()` is called then `(1.1 - 1) * 10_000 = 1000` Dollars are minted
 * to the current contract.
 *
 */
interface IDollarMintCalculator {
    /**
     * @notice Returns amount of Dollars to be minted based on formula `(TWAP_PRICE - 1) * DOLLAR_TOTAL_SUPPLY`
     * @return Amount of Dollars to be minted
     */
    function getDollarsToMint() external view returns (uint256);
}
