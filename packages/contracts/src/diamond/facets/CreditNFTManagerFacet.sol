// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import {LibCreditNFTManager} from "../libraries/LibCreditNFTManager.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

/// @title A basic credit issuing and redemption mechanism for Credit NFT holders
/// @notice Allows users to burn their Ubiquity Dollar in exchange for Credit NFT
/// redeemable in the future
/// @notice Allows users to redeem individual Credit NFT or batch redeem
/// Credit NFT on a first-come first-serve basis
contract CreditNFTManagerFacet is Modifiers {
    function setExpiredCreditNFTConversionRate(
        uint256 rate
    ) external onlyCreditNFTManager {
        LibCreditNFTManager.setExpiredCreditNFTConversionRate(rate);
    }

    function expiredCreditNFTConversionRate() external view returns (uint256) {
        return LibCreditNFTManager.expiredCreditNFTConversionRate();
    }

    function setCreditNFTLength(
        uint256 creditNFTLengthBlocks
    ) external onlyCreditNFTManager {
        LibCreditNFTManager.setCreditNFTLength(creditNFTLengthBlocks);
    }

    function creditNFTLengthBlocks() external view returns (uint256) {
        return LibCreditNFTManager.creditNFTLengthBlocks();
    }

    /// @dev called when a user wants to burn Ubiquity Dollar for Credit NFT.
    ///      should only be called when oracle is below a dollar
    /// @param amount the amount of dollars to exchange for Credit NFT
    function exchangeDollarsForCreditNFT(
        uint256 amount
    ) external returns (uint256) {
        return LibCreditNFTManager.exchangeDollarsForCreditNFT(amount);
    }

    /// @dev called when a user wants to burn Dollar for Credit.
    ///      should only be called when oracle is below a dollar
    /// @param amount the amount of dollars to exchange for Credit
    /// @return amount of Credit tokens minted
    function exchangeDollarsForCredit(
        uint256 amount
    ) external returns (uint256) {
        return LibCreditNFTManager.exchangeDollarsForCredit(amount);
    }

    /// @dev uses the current Credit NFT for dollars calculation to get Credit NFT for dollars
    /// @param amount the amount of dollars to exchange for Credit NFT
    function getCreditNFTReturnedForDollars(
        uint256 amount
    ) external view returns (uint256) {
        return LibCreditNFTManager.getCreditNFTReturnedForDollars(amount);
    }

    /// @dev uses the current Credit for dollars calculation to get Credit for dollars
    /// @param amount the amount of dollars to exchange for Credit
    function getCreditReturnedForDollars(
        uint256 amount
    ) external view returns (uint256) {
        return LibCreditNFTManager.getCreditReturnedForDollars(amount);
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
            LibCreditNFTManager.onERC1155Received(
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
    function burnExpiredCreditNFTForGovernance(
        uint256 id,
        uint256 amount
    ) public returns (uint256 governanceAmount) {
        return
            LibCreditNFTManager.burnExpiredCreditNFTForGovernance(id, amount);
    }

    // TODO should we leave it ?
    /// @dev Lets Credit NFT holder burn Credit NFT for Credit. Doesn't make TWAP > 1 check.
    /// @param id the timestamp of the Credit NFT
    /// @param amount the amount of Credit NFT to redeem
    /// @return amount of Credit pool tokens (i.e. LP tokens) minted to Credit NFT holder
    function burnCreditNFTForCredit(
        uint256 id,
        uint256 amount
    ) public returns (uint256) {
        return LibCreditNFTManager.burnCreditNFTForCredit(id, amount);
    }

    /// @dev Exchange Credit pool token for Dollar tokens.
    /// @param amount Amount of Credit tokens to burn in exchange for Dollar tokens.
    /// @return amount of unredeemed Credit
    function burnCreditTokensForDollars(
        uint256 amount
    ) public returns (uint256) {
        return LibCreditNFTManager.burnCreditTokensForDollars(amount);
    }

    /// @param id the block number of the Credit NFT
    /// @param amount the amount of Credit NFT to redeem
    /// @return amount of unredeemed Credit NFT
    function redeemCreditNFT(
        uint256 id,
        uint256 amount
    ) public returns (uint256) {
        return LibCreditNFTManager.redeemCreditNFT(id, amount);
    }

    function mintClaimableDollars() public {
        LibCreditNFTManager.mintClaimableDollars();
    }
}
