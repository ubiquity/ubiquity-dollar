// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/// @title A mechanism for calculating dollars to be minted
interface IDollarMintCalculator {
    function getDollarsToMint() external view returns (uint256);
}
