// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

/// @title A mechanism for calculating Credit NFTs received for a dollar amount burnt
interface ICreditNftRedemptionCalculator {
    function getCreditNftAmount(
        uint256 dollarsToBurn
    ) external view returns (uint256);
}
