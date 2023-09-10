// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IDollarMintCalculator} from "../../dollar/interfaces/IDollarMintCalculator.sol";
import {LibDollarMintCalculator} from "../libraries/LibDollarMintCalculator.sol";

/// @notice Calculates amount of Dollars ready to be minted when TWAP price (i.e. Dollar price) > 1$
contract DollarMintCalculatorFacet is IDollarMintCalculator {
    /// @inheritdoc IDollarMintCalculator
    function getDollarsToMint() external view override returns (uint256) {
        return LibDollarMintCalculator.getDollarsToMint();
    }
}
