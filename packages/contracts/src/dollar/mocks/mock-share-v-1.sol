// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../core/erc-1155-ubiquity.sol";

contract BondingShare is ERC1155Ubiquity {
    // solhint-disable-next-line no-empty-blocks
    constructor(address _diamond) ERC1155Ubiquity(_diamond, "URI") {}
}
