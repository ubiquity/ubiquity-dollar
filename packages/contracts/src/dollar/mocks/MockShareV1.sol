// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../core/ERC1155Ubiquity.sol";
import {Initializable} from "@openzeppelinUpgradeable/contracts/proxy/utils/Initializable.sol";

contract BondingShare is Initializable, ERC1155Ubiquity {
    // solhint-disable-next-line no-empty-blocks
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _manager,
        string memory uri
    ) public initializer {
        __ERC1155Ubiquity_init(_manager, uri);
    }
}
