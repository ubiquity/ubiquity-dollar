// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../../dollar/interfaces/ICreditRedemptionCalculator.sol";

import {Modifiers} from "../libraries/LibAppStorage.sol";
import {LibCreditRedemptionCalculator} from "../libraries/LibCreditRedemptionCalculator.sol";

/// @notice Contract facet for calculating amount of Credits to mint on Dollars burn
contract CreditRedemptionCalculatorFacet is
    Modifiers,
    ICreditRedemptionCalculator
{
    /**
     * @notice Sets the `p` param in the Credit mint calculation formula:
     * `y = x * ((BlockDebtStart / BlockBurn) ^ p)`
     * @param coef New `p` param in wei
     */
    function setConstant(uint256 coef) external onlyIncentiveAdmin {
        LibCreditRedemptionCalculator.setConstant(coef);
    }

    /**
     * @notice Returns the `p` param used in the Credit mint calculation formula
     * @return `p` param
     */
    function getConstant() external view returns (uint256) {
        return LibCreditRedemptionCalculator.getConstant();
    }

    /// @inheritdoc ICreditRedemptionCalculator
    function getCreditAmount(
        uint256 dollarsToBurn,
        uint256 blockHeightDebt
    ) external view override returns (uint256) {
        return
            LibCreditRedemptionCalculator.getCreditAmount(
                dollarsToBurn,
                blockHeightDebt
            );
    }
}
