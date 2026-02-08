// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IDollarMintExcess} from "../../dollar/interfaces/IDollarMintExcess.sol";
import {LibDollarMintExcess} from "../libraries/LibDollarMintExcess.sol";

/**
 * @notice Contract facet for distributing excess Dollars when `mintClaimableDollars()` is called
 * @notice Excess Dollars are distributed this way:
 * - 50% goes to the treasury address
 * - 10% goes for burning Dollar-Governance LP tokens in a DEX pool
 * - 40% goes to the Staking contract
 */
contract DollarMintExcessFacet is IDollarMintExcess {
    /// @inheritdoc IDollarMintExcess
    function distributeDollars() external override {
        LibDollarMintExcess.distributeDollars();
    }
}
