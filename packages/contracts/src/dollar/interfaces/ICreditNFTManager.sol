// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/// @title A Credit NFT redemption mechanism for Credit NFT holders
/// @notice Allows users to redeem individual Credit NFT or batch redeem Credit NFT
/// @dev Implements IERC1155Receiver so that it can deal with redemptions
interface ICreditNFTManager is IERC1155Receiver {
    function redeemCreditNFT(address from, uint256 id, uint256 amount) external;

    function exchangeDollarsForCreditNFT(uint256 amount) external;
}
