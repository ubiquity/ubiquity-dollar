// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {LibCurveDollarIncentive} from "../libraries/LibCurveDollarIncentive.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

contract CurveDollarIncentiveFacet is Modifiers {

    function incentivize(
        address sender,
        address receiver,
        uint256 amountIn
    ) external {
        LibCurveDollarIncentive.incentivize(
            sender,
            receiver,
            amountIn
        );
    }

    /// @notice set an address to be exempted from Curve trading incentives
    /// @param account the address to update
    /// @param isExempt a flag for whether to flag as exempt or not
    function setExemptAddress(
        address account,
        bool isExempt
    ) external {
        LibCurveDollarIncentive.setExemptAddress(account, isExempt);
    }

    /// @notice switch the sell penalty
    function switchSellPenalty() external {
        LibCurveDollarIncentive.switchSellPenalty();
    }

    /// @notice switch the buy incentive
    function switchBuyIncentive() external {
        LibCurveDollarIncentive.switchBuyIncentive();
    }

    /// @notice returns true if account is marked as exempt
    function isExemptAddress(address account) external view returns (bool) {
        return LibCurveDollarIncentive.isExemptAddress(account);
    }
}