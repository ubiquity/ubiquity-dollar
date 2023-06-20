// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ierc-1155-receiver.sol";

/// @title A Credit NFT redemption mechanism for Credit NFT holders
/// @notice Allows users to redeem individual Credit NFT or batch redeem Credit NFT
/// @dev Implements IERC1155Receiver so that it can deal with redemptions
interface ICreditNftManager is IERC1155Receiver {
    function redeemCreditNft(address from, uint256 id, uint256 amount) external;

    function exchangeDollarsForCreditNft(uint256 amount) external;
}
