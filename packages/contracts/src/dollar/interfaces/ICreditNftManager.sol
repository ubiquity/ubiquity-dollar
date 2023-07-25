// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/**
 * @notice Interface for basic credit issuing and redemption mechanism for Credit NFT and Credit holders
 * @notice Allows users to burn their Dollars in exchange for Credit NFTs or Credits redeemable in the future
 * @notice Allows users to:
 * - redeem individual Credit NFT or batch redeem Credit NFT on a first-come first-serve basis
 * - redeem Credits for Dollars
 * @dev Implements `IERC1155Receiver` so that it can deal with redemptions
 */
interface ICreditNftManager is IERC1155Receiver {
    /**
     * @notice Burns Credit NFTs for Dollars when Dollar price > 1$
     * @param id Credit NFT expiry block number
     * @param amount Amount of Credit NFTs to burn
     * @return Amount of unredeemed Credit NFTs
     */
    function redeemCreditNft(
        uint256 id,
        uint256 amount
    ) external returns (uint);

    /**
     * @notice Burns Dollars in exchange for Credit NFTs
     * @notice Should only be called when Dollar price < 1$
     * @param amount Amount of Dollars to exchange for Credit NFTs
     * @return Expiry block number when Credit NFTs can no longer be redeemed for Dollars
     */
    function exchangeDollarsForCreditNft(
        uint256 amount
    ) external returns (uint);
}
