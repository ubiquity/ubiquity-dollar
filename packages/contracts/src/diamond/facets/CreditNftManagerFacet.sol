// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {LibCreditNftManager} from "../libraries/LibCreditNftManager.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

/// @title A basic credit issuing and redemption mechanism for Credit NFT holders
/// @notice Allows users to burn their Ubiquity Dollar in exchange for Credit NFT
/// redeemable in the future
/// @notice Allows users to redeem individual Credit NFT or batch redeem
/// Credit NFT on a first-come first-serve basis
contract CreditNftManagerFacet is Modifiers {
    function setExpiredCreditNftConversionRate(
        uint256 rate
    ) external onlyCreditNftManager {
        LibCreditNftManager.setExpiredCreditNftConversionRate(rate);
    }

    function expiredCreditNftConversionRate() external view returns (uint256) {
        return LibCreditNftManager.expiredCreditNftConversionRate();
    }

    function setCreditNftLength(
        uint256 _creditNftLengthBlocks
    ) external onlyCreditNftManager {
        LibCreditNftManager.setCreditNftLength(_creditNftLengthBlocks);
    }

    function creditNftLengthBlocks() external view returns (uint256) {
        return LibCreditNftManager.creditNftLengthBlocks();
    }

    /// @dev called when a user wants to burn Ubiquity Dollar for Credit NFT.
    ///      should only be called when oracle is below a dollar
    /// @param amount the amount of dollars to exchange for Credit NFT
    function exchangeDollarsForCreditNft(
        uint256 amount
    ) external returns (uint256) {
        return LibCreditNftManager.exchangeDollarsForCreditNft(amount);
    }

    /// @dev called when a user wants to burn Dollar for Credit.
    ///      should only be called when oracle is below a dollar
    /// @param amount the amount of dollars to exchange for Credit
    /// @return amount of Credit tokens minted
    function exchangeDollarsForCredit(
        uint256 amount
    ) external returns (uint256) {
        return LibCreditNftManager.exchangeDollarsForCredit(amount);
    }

    /// @dev uses the current Credit NFT for dollars calculation to get Credit NFT for dollars
    /// @param amount the amount of dollars to exchange for Credit NFT
    function getCreditNftReturnedForDollars(
        uint256 amount
    ) external view returns (uint256) {
        return LibCreditNftManager.getCreditNftReturnedForDollars(amount);
    }

    /// @dev uses the current Credit for dollars calculation to get Credit for dollars
    /// @param amount the amount of dollars to exchange for Credit
    function getCreditReturnedForDollars(
        uint256 amount
    ) external view returns (uint256) {
        return LibCreditNftManager.getCreditReturnedForDollars(amount);
    }

    /// @dev should be called by this contract only when getting Credit NFT to be burnt
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

    /// @dev this method is never called by the contract so if called,
    /// it was called by someone else -> revert.
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

    /// @dev let Credit NFT holder burn expired Credit NFT for Governance Token. Doesn't make TWAP > 1 check.
    /// @param id the timestamp of the Credit NFT
    /// @param amount the amount of Credit NFT to redeem
    /// @return governanceAmount amount of Governance Token minted to Credit NFT holder
    function burnExpiredCreditNftForGovernance(
        uint256 id,
        uint256 amount
    ) public returns (uint256 governanceAmount) {
        return
            LibCreditNftManager.burnExpiredCreditNftForGovernance(id, amount);
    }

    // TODO should we leave it ?
    /// @dev Lets Credit NFT holder burn Credit NFT for Credit. Doesn't make TWAP > 1 check.
    /// @param id the timestamp of the Credit NFT
    /// @param amount the amount of Credit NFT to redeem
    /// @return amount of Credit pool tokens (i.e. LP tokens) minted to Credit Nft holder
    function burnCreditNftForCredit(
        uint256 id,
        uint256 amount
    ) public returns (uint256) {
        return LibCreditNftManager.burnCreditNftForCredit(id, amount);
    }

    /// @dev Exchange Credit pool token for Dollar tokens.
    /// @param amount Amount of Credit tokens to burn in exchange for Dollar tokens.
    /// @return amount of unredeemed Credit
    function burnCreditTokensForDollars(
        uint256 amount
    ) public returns (uint256) {
        return LibCreditNftManager.burnCreditTokensForDollars(amount);
    }

    /// @param id the block number of the Credit NFT
    /// @param amount the amount of Credit NFT to redeem
    /// @return amount of unredeemed Credit NFT
    function redeemCreditNft(
        uint256 id,
        uint256 amount
    ) public returns (uint256) {
        return LibCreditNftManager.redeemCreditNft(id, amount);
    }

    function mintClaimableDollars() public {
        LibCreditNftManager.mintClaimableDollars();
    }
}
