// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IDollarMintExcess} from "../../dollar/interfaces/i-dollar-mint-excess.sol";
import {LibDollarMintExcess} from "../libraries/lib-dollar-mint-excess.sol";

/// @title An excess dollar distributor which sends dollars to treasury,
/// lp rewards and inflation rewards
contract DollarMintExcessFacet is IDollarMintExcess {
    function distributeDollars() external override {
        LibDollarMintExcess.distributeDollars();
    }
}
