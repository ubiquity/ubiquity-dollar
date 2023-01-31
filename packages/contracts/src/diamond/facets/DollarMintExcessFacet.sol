// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {IDollarMintExcess} from "../../dollar/interfaces/IDollarMintExcess.sol";
import {LibDollarMintExcess} from "../libraries/LibDollarMintExcess.sol";

/// @title An excess dollar distributor which sends dollars to treasury,
/// lp rewards and inflation rewards
contract DollarMintExcessFacet is IDollarMintExcess {
    function distributeDollars() external override {
        LibDollarMintExcess.distributeDollars();
    }
}
