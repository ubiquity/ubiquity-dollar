// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {IDollarMintCalculator} from "../../dollar/interfaces/IDollarMintCalculator.sol";
import {LibDollarMintCalculator} from "../libraries/LibDollarMintCalculator.sol";

/// @title Calculates amount of dollars ready to be minted when twapPrice > 1
contract DollarMintCalculatorFacet is IDollarMintCalculator {
    /// @notice returns (TWAP_PRICE  -1) * Ubiquity_Dollar_Total_Supply
    function getDollarsToMint() external view override returns (uint256) {
        return LibDollarMintCalculator.getDollarsToMint();
    }
}
