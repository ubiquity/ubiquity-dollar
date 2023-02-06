// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "../ERC1155Ubiquity.sol";
import "src/dollar/core/UbiquityDollarManager.sol";

contract BondingShare is ERC1155Ubiquity {
    // solhint-disable-next-line no-empty-blocks
    constructor(
        UbiquityDollarManager manager_
    ) ERC1155Ubiquity(manager_, "URI") {}
}
