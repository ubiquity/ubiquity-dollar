// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ierc-1155-receiver.sol";

/// @title A mechanism for calculating dollars to be minted
interface IDollarMintCalculator {
    function getDollarsToMint() external view returns (uint256);
}
