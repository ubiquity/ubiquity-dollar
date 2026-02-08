// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {LibCreditNftManager} from "../libraries/LibCreditNftManager.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

/**
 * @notice Contract facet for basic credit issuing and redemption mechanism for Credit NFT and Credit holders
 * @notice Allows users to burn their Dollars in exchange for Credit NFTs or Credits redeemable in the future
 * @notice Allows users to:
 * - redeem individual Credit NFT or batch redeem Credit NFT on a first-come first-serve basis
 * - redeem Credits for Dollars
 */
contract CreditNftManagerFacet is Modifiers {
    /**
     * @notice Credit NFT to Governance conversion rate
     * @notice When Credit NFTs are expired they can be converted to
     * Governance tokens using `rate` conversion rate
     * @param rate Credit NFT to Governance tokens conversion rate
     */
    function setExpiredCreditNftConversionRate(
        uint256 rate
    ) external onlyCreditNftManager {
        LibCreditNftManager.setExpiredCreditNftConversionRate(rate);
    }

    /**
     * @notice Returns Credit NFT to Governance conversion rate
     * @return Conversion rate
     */
    function expiredCreditNftConversionRate() external view returns (uint256) {
        return LibCreditNftManager.expiredCreditNftConversionRate();
    }

    /**
     * @notice Sets Credit NFT block lifespan
     * @param _creditNftLengthBlocks The number of blocks during which Credit NFTs can be
     * redeemed for Dollars
     */
    function setCreditNftLength(
        uint256 _creditNftLengthBlocks
    ) external onlyCreditNftManager {
        LibCreditNftManager.setCreditNftLength(_creditNftLengthBlocks);
    }

    /**
     * @notice Returns Credit NFT block lifespan
     * @return Number of blocks during which Credit NFTs can be
     * redeemed for Dollars
     */
    function creditNftLengthBlocks() external view returns (uint256) {
        return LibCreditNftManager.creditNftLengthBlocks();
    }

    /**
     * @notice Burns Dollars in exchange for Credit NFTs
     * @notice Should only be called when Dollar price < 1$
     * @param amount Amount of Dollars to exchange for Credit NFTs
     * @return Expiry block number when Credit NFTs can no longer be redeemed for Dollars
     */
    function exchangeDollarsForCreditNft(
        uint256 amount
    ) external returns (uint256) {
        return LibCreditNftManager.exchangeDollarsForCreditNft(amount);
    }

    /**
     * @notice Burns Dollars in exchange for Credit tokens
     * @notice Should only be called when Dollar price < 1$
     * @param amount Amount of Dollars to burn
     * @return Amount of Credits minted
     */
    function exchangeDollarsForCredit(
        uint256 amount
    ) external returns (uint256) {
        return LibCreditNftManager.exchangeDollarsForCredit(amount);
    }

    /**
     * @notice Returns amount of Credit NFTs to be minted for the `amount` of Dollars to burn
     * @param amount Amount of Dollars to burn
     * @return Amount of Credit NFTs to be minted
     */
    function getCreditNftReturnedForDollars(
        uint256 amount
    ) external view returns (uint256) {
        return LibCreditNftManager.getCreditNftReturnedForDollars(amount);
    }

    /**
     * @notice Returns the amount of Credit tokens to be minter for the provided `amount` of Dollars to burn
     * @param amount Amount of Dollars to burn
     * @return Amount of Credits to be minted
     */
    function getCreditReturnedForDollars(
        uint256 amount
    ) external view returns (uint256) {
        return LibCreditNftManager.getCreditReturnedForDollars(amount);
    }

    /**
     * @notice Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external view returns (bytes4) {
        return
            LibCreditNftManager.onERC1155Received(
                operator,
                from,
                id,
                value,
                data
            );
    }

    /**
     * @notice Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure returns (bytes4) {
        //reject the transfer
        return "";
    }

    /**
     * @notice Burns expired Credit NFTs for Governance tokens at `expiredCreditNftConversionRate` rate
     * @param id Credit NFT timestamp
     * @param amount Amount of Credit NFTs to burn
     * @return governanceAmount Amount of Governance tokens minted to Credit NFT holder
     */
    function burnExpiredCreditNftForGovernance(
        uint256 id,
        uint256 amount
    ) public returns (uint256 governanceAmount) {
        return
            LibCreditNftManager.burnExpiredCreditNftForGovernance(id, amount);
    }

    /**
     * TODO: Should we leave it ?
     * @notice Burns Credit NFTs for Credit tokens
     * @param id Credit NFT timestamp
     * @param amount Amount of Credit NFTs to burn
     * @return Credit tokens balance of `msg.sender`
     */
    function burnCreditNftForCredit(
        uint256 id,
        uint256 amount
    ) public returns (uint256) {
        return LibCreditNftManager.burnCreditNftForCredit(id, amount);
    }

    /**
     * @notice Burns Credit tokens for Dollars when Dollar price > 1$
     * @param amount Amount of Credits to burn
     * @return Amount of unredeemed Credits
     */
    function burnCreditTokensForDollars(
        uint256 amount
    ) public returns (uint256) {
        return LibCreditNftManager.burnCreditTokensForDollars(amount);
    }

    /**
     * @notice Burns Credit NFTs for Dollars when Dollar price > 1$
     * @param id Credit NFT expiry block number
     * @param amount Amount of Credit NFTs to burn
     * @return Amount of unredeemed Credit NFTs
     */
    function redeemCreditNft(
        uint256 id,
        uint256 amount
    ) public returns (uint256) {
        return LibCreditNftManager.redeemCreditNft(id, amount);
    }

    /**
     * @notice Mints Dollars when Dollar price > 1$
     * @notice Distributes excess Dollars this way:
     * - 50% goes to the treasury address
     * - 10% goes for burning Dollar-Governance LP tokens in a DEX pool
     * - 40% goes to the Staking contract
     */
    function mintClaimableDollars() public {
        LibCreditNftManager.mintClaimableDollars();
    }
}
