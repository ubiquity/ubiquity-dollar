// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "../ERC1155Ubiquity.sol";
import "src/dollar/core/UbiquityDollarManager.sol";

//cspell:disable
contract MockBondingShareV1 is ERC1155Ubiquity {
    // solhint-disable-next-line no-empty-blocks
    constructor(
        UbiquityDollarManager manager_
    ) ERC1155Ubiquity(manager_, "URI") {}
}
