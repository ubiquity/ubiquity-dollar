// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LibStabilityPool} from "../libraries/LibStabilityPool.sol";

/**
 * @title IStabilityPoolFacet
 * @notice Interface for the Stability Pool facet
 * @notice Integrates Liquity V1 Stability Pool to generate yield on LUSD collateral
 */
interface IStabilityPoolFacet {
    //=====================
    // Views
    //=====================

    /**
     * @notice Returns the total LUSD principal deposited in the Stability Pool
     * @return Total principal in the pool
     */
    function totalPrincipalInPool() external view returns (uint256);

    /**
     * @notice Returns the current compounded LUSD deposit in the Stability Pool
     * @return Current LUSD balance in the Stability Pool
     */
    function currentLusdInStabilityPool() external view returns (uint256);

    /**
     * @notice Returns the pending ETH rewards from the Stability Pool
     * @return Pending ETH reward amount
     */
    function pendingEthReward() external view returns (uint256);

    /**
     * @notice Returns the pending LQTY rewards from the Stability Pool
     * @return Pending LQTY reward amount
     */
    function pendingLqtyReward() external view returns (uint256);

    /**
     * @notice Returns whether the Stability Pool integration is active
     * @return True if active
     */
    function isStabilityPoolActive() external view returns (bool);

    /**
     * @notice Returns the harvest reward threshold
     * @return Threshold in wei
     */
    function harvestRewardThreshold() external view returns (uint256);

    /**
     * @notice Returns the compounding percentage
     * @return Percentage with 1e6 = 100%
     */
    function compoundingPercentage() external view returns (uint256);

    /**
     * @notice Returns the protocol treasury address
     * @return Treasury address
     */
    function protocolTreasury() external view returns (address);

    //====================
    // Public functions
    //====================

    /**
     * @notice Deposits LUSD into the Liquity Stability Pool
     * @param amount Amount of LUSD to deposit
     */
    function depositToPool(uint256 amount) external;

    /**
     * @notice Withdraws LUSD principal from the Liquity Stability Pool
     * @param amount Amount of LUSD to withdraw
     */
    function withdrawFromPool(uint256 amount) external;

    /**
     * @notice Harvests ETH and LQTY rewards from the Stability Pool
     */
    function harvestRewards() external;

    //========================
    // Admin functions
    //========================

    /**
     * @notice Sets the Liquity Stability Pool address
     * @param newStabilityPoolAddress New Stability Pool address
     */
    function setStabilityPoolAddress(
        address newStabilityPoolAddress
    ) external;

    /**
     * @notice Sets the LUSD token address
     * @param newLusdTokenAddress New LUSD token address
     */
    function setLusdTokenAddress(address newLusdTokenAddress) external;

    /**
     * @notice Sets the LQTY token address
     * @param newLqtyTokenAddress New LQTY token address
     */
    function setLqtyTokenAddress(address newLqtyTokenAddress) external;

    /**
     * @notice Sets the protocol treasury address
     * @param newProtocolTreasury New treasury address
     */
    function setProtocolTreasury(address newProtocolTreasury) external;

    /**
     * @notice Sets the minimum ETH reward threshold for triggering harvests
     * @param newThreshold New threshold in wei
     */
    function setHarvestRewardThreshold(uint256 newThreshold) external;

    /**
     * @notice Sets the compounding percentage for reward distribution
     * @param newPercentage New percentage (1e6 = 100%)
     */
    function setCompoundingPercentage(uint256 newPercentage) external;

    /**
     * @notice Toggles the Stability Pool integration on/off
     */
    function toggleStabilityPool() external;
}
