// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/**
 * @notice Contract interface for calculating amount of Credit NFTs to mint on Dollars burn
 * @notice Users can burn their Dollars in exchange for Credit NFTs which are minted with a premium.
 * Premium is calculated with the following formula: `1 / ((1 - R) ^ 2) - 1` where `R` represents Credit NFT
 * total oustanding debt divived by Dollar total supply. When users burn Dollars and mint Credit NFTs then
 * total oustading debt of Credit NFT is increased. On the contrary, when Credit NFTs are burned then
 * Credit NFT total oustanding debt is decreased.
 *
 * @notice Example:
 * 1. Dollar total supply: 10_000, Credit NFT total oustanding debt: 100, User burns: 200 Dollars
 * 2. When user burns 200 Dollars then `200 + 200 * (1 / ((1 - (100 / 10_000)) ^ 2) - 1) = ~204.06` Credit NFTs are minted
 *
 * @notice Example:
 * 1. Dollar total supply: 10_000, Credit NFT total oustanding debt: 9_000, User burns: 200 Dollars
 * 2. When user burns 200 Dollars then `200 + 200 * (1 / ((1 - (9_000 / 10_000)) ^ 2) - 1) = 20_000` Credit NFTs are minted
 *
 * @notice So the more Credit NFT oustanding debt (i.e. Credit NFT total supply) the more premium applied for minting Credit NFTs
 *
 * @dev 1 Credit NFT = 1 whole Ubiquity Dollar, not 1 wei
 */
interface ICreditNftRedemptionCalculator {
    /**
     * @notice Returns Credit NFT amount minted for `dollarsToBurn` amount of Dollars to burn
     * @param dollarsToBurn Amount of Dollars to burn
     * @return Amount of Credit NFTs to mint
     */
    function getCreditNftAmount(
        uint256 dollarsToBurn
    ) external view returns (uint256);
}
