// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ICreditNftRedemptionCalculator} from "../../dollar/interfaces/ICreditNftRedemptionCalculator.sol";
import {LibCreditNftRedemptionCalculator} from "../libraries/LibCreditNftRedemptionCalculator.sol";

/// @notice Contract facet for calculating amount of Credit NFTs to mint on Dollars burn
contract CreditNftRedemptionCalculatorFacet is ICreditNftRedemptionCalculator {
    /// @inheritdoc ICreditNftRedemptionCalculator
    function getCreditNftAmount(
        uint256 dollarsToBurn
    ) external view override returns (uint256) {
        return
            LibCreditNftRedemptionCalculator.getCreditNftAmount(dollarsToBurn);
    }
}
