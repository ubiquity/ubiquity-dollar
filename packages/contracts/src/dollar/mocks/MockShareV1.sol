// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {StakingShare} from "../../../src/dollar/core/StakingShare.sol";

contract BondingShare is StakingShare {
    // solhint-disable-next-line no-empty-blocks
    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _manager,
        string memory uri
    ) public override initializer {
        __ERC1155Ubiquity_init(_manager, uri);
    }

    function hasUpgraded() public pure virtual returns (bool) {
        return true;
    }

    function getVersion() public view virtual returns (uint8) {
        return super._getInitializedVersion();
    }

    function getImpl() public view virtual returns (address) {
        return super._getImplementation();
    }
}
