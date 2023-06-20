// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/ierc-20.sol";
import {ICreditNftRedemptionCalculator} from "../../dollar/interfaces/i-credit-nft-redemption-calculator.sol";
import {LibCreditNftRedemptionCalculator} from "../libraries/lib-credit-nft-redemption-calculator.sol";

/// @title Uses the following formula: ((1/(1-R)^2) - 1)
contract CreditNftRedemptionCalculatorFacet is ICreditNftRedemptionCalculator {
    function getCreditNftAmount(
        uint256 dollarsToBurn
    ) external view override returns (uint256) {
        return
            LibCreditNftRedemptionCalculator.getCreditNFTAmount(dollarsToBurn);
    }
}
