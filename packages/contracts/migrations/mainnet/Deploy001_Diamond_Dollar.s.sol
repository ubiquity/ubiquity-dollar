// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Deploy001_Diamond_Dollar as Deploy001_Diamond_Dollar_Development} from "../development/Deploy001_Diamond_Dollar.s.sol";

/// @notice Migration contract
contract Deploy001_Diamond_Dollar is Deploy001_Diamond_Dollar_Development {
    function run() public override {
        // Run migration for testnet because "Deploy001_Diamond_Dollar" migration
        // is identical both for development and mainnet
        super.run();
    }
}
