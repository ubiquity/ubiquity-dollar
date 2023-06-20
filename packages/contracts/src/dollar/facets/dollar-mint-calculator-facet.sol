// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IDollarMintCalculator} from "../../dollar/interfaces/i-dollar-mint-calculator.sol";
import {LibDollarMintCalculator} from "../libraries/lib-dollar-mint-calculator.sol";

/// @title Calculates amount of dollars ready to be minted when twapPrice > 1
contract DollarMintCalculatorFacet is IDollarMintCalculator {
    /// @notice returns (TWAP_PRICE  -1) * Ubiquity_Dollar_Total_Supply
    function getDollarsToMint() external view override returns (uint256) {
        return LibDollarMintCalculator.getDollarsToMint();
    }
}
