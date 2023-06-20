// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ierc-1155-receiver.sol";

/// @title A mechanism for distributing excess dollars to relevant places
interface IDollarMintExcess {
    function distributeDollars() external;
}
