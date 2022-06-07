// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.10;


/**
 @title RateCalculator Interface
 @notice Rate Calculator to provide several kinds of rate formula
 */
interface IRateCalculator {
    /**
     @notice get Get `uCRAmount` for input `amount`.
     @param amount Vault token amount to swap.
     @return uCRAmount uCR token amount for input `amount`.
    */
    function getUCRAmount(
        uint256 amount
    ) public returns (uint256 uCRAmount);
}
