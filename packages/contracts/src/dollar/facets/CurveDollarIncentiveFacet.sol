// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LibCurveDollarIncentive} from "../libraries/LibCurveDollarIncentive.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

/**
 * @notice Facet adds buy incentive and sell penalty for Curve's Dollar-3CRV MetaPool
 */
contract CurveDollarIncentiveFacet is Modifiers {
    /**
     * @notice Adds buy and sell incentives
     * @param sender Sender address
     * @param receiver Receiver address
     * @param amountIn Trade amount
     */
    function incentivize(
        address sender,
        address receiver,
        uint256 amountIn
    ) external onlyDollarManager {
        LibCurveDollarIncentive.incentivize(sender, receiver, amountIn);
    }

    /**
     * @notice Sets an address to be exempted from Curve trading incentives
     * @param account Address to update
     * @param isExempt Flag for whether to flag as exempt or not
     */
    function setExemptAddress(
        address account,
        bool isExempt
    ) external onlyAdmin {
        LibCurveDollarIncentive.setExemptAddress(account, isExempt);
    }

    /// @notice Switches the sell penalty
    function switchSellPenalty() external onlyAdmin {
        LibCurveDollarIncentive.switchSellPenalty();
    }

    /// @notice Switches the buy incentive
    function switchBuyIncentive() external onlyAdmin {
        LibCurveDollarIncentive.switchBuyIncentive();
    }

    /**
     * @notice Checks whether sell penalty is enabled
     * @return Whether sell penalty is enabled
     */
    function isSellPenaltyOn() external view returns (bool) {
        return LibCurveDollarIncentive.isSellPenaltyOn();
    }

    /**
     * @notice Checks whether buy incentive is enabled
     * @return Whether buy incentive is enabled
     */
    function isBuyIncentiveOn() external view returns (bool) {
        return LibCurveDollarIncentive.isBuyIncentiveOn();
    }

    /**
     * @notice Checks whether `account` is marked as exempt
     * @notice Whether `account` is exempt from buy incentive and sell penalty
     */
    function isExemptAddress(address account) external view returns (bool) {
        return LibCurveDollarIncentive.isExemptAddress(account);
    }
}
