// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../../dollar/interfaces/ICreditNFTRedemptionCalculator.sol"; 

/// @title Uses the following formula: ((1/(1-R)^2) - 1)
contract CreditNFTRedemptionCalculatorFacet is ICreditNFTRedemptionCalculator { 
 
 
    function getCreditNFTAmount(
        uint256 dollarsToBurn
    ) external view override returns (uint256) {
         
        return LibCreditNFTRedemptionCalculator.getCreditNFTAmount(dollarsToBurn);
    }
}
