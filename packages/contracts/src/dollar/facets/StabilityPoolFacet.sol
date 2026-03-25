// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import {IStabilityPoolFacet} from "../interfaces/IStabilityPoolFacet.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";
import {LibStabilityPool} from "../libraries/LibStabilityPool.sol";

/**
 * @title StabilityPoolFacet
 * @notice Diamond facet for integrating Liquity V1 Stability Pool
 * @notice Auto-deposits LUSD collateral to the Stability Pool for yield generation (~6.28% APR).
 *         Harvests ETH/LQTY rewards during redeems for buybacks/compounding (protocol-owned only).
 *         Operations piggyback on user transactions for gas efficiency.
 */
contract StabilityPoolFacet is IStabilityPoolFacet, Modifiers {
    //=====================
    // Views
    //=====================

    /// @inheritdoc IStabilityPoolFacet
    function totalPrincipalInPool() external view returns (uint256) {
        return LibStabilityPool.totalPrincipalInPool();
    }

    /// @inheritdoc IStabilityPoolFacet
    function currentLusdInStabilityPool() external view returns (uint256) {
        return LibStabilityPool.currentLusdInStabilityPool();
    }

    /// @inheritdoc IStabilityPoolFacet
    function pendingEthReward() external view returns (uint256) {
        return LibStabilityPool.pendingEthReward();
    }

    /// @inheritdoc IStabilityPoolFacet
    function pendingLqtyReward() external view returns (uint256) {
        return LibStabilityPool.pendingLqtyReward();
    }

    /// @inheritdoc IStabilityPoolFacet
    function isStabilityPoolActive() external view returns (bool) {
        return LibStabilityPool.isActive();
    }

    /// @inheritdoc IStabilityPoolFacet
    function harvestRewardThreshold() external view returns (uint256) {
        return LibStabilityPool.harvestRewardThreshold();
    }

    /// @inheritdoc IStabilityPoolFacet
    function compoundingPercentage() external view returns (uint256) {
        return LibStabilityPool.compoundingPercentage();
    }

    /// @inheritdoc IStabilityPoolFacet
    function protocolTreasury() external view returns (address) {
        return LibStabilityPool.protocolTreasury();
    }

    //====================
    // Public functions
    //====================

    /// @inheritdoc IStabilityPoolFacet
    function depositToPool(uint256 amount) external nonReentrant onlyAdmin {
        LibStabilityPool.depositToPool(amount);
    }

    /// @inheritdoc IStabilityPoolFacet
    function withdrawFromPool(uint256 amount) external nonReentrant onlyAdmin {
        LibStabilityPool.withdrawFromPool(amount);
    }

    /// @inheritdoc IStabilityPoolFacet
    function harvestRewards() external nonReentrant onlyAdmin {
        LibStabilityPool.harvestRewards();
    }

    //========================
    // Admin functions
    //========================

    /// @inheritdoc IStabilityPoolFacet
    function setStabilityPoolAddress(
        address newStabilityPoolAddress
    ) external onlyAdmin {
        LibStabilityPool.setStabilityPoolAddress(newStabilityPoolAddress);
    }

    /// @inheritdoc IStabilityPoolFacet
    function setLusdTokenAddress(
        address newLusdTokenAddress
    ) external onlyAdmin {
        LibStabilityPool.setLusdTokenAddress(newLusdTokenAddress);
    }

    /// @inheritdoc IStabilityPoolFacet
    function setLqtyTokenAddress(
        address newLqtyTokenAddress
    ) external onlyAdmin {
        LibStabilityPool.setLqtyTokenAddress(newLqtyTokenAddress);
    }

    /// @inheritdoc IStabilityPoolFacet
    function setProtocolTreasury(
        address newProtocolTreasury
    ) external onlyAdmin {
        LibStabilityPool.setProtocolTreasury(newProtocolTreasury);
    }

    /// @inheritdoc IStabilityPoolFacet
    function setHarvestRewardThreshold(
        uint256 newThreshold
    ) external onlyAdmin {
        LibStabilityPool.setHarvestRewardThreshold(newThreshold);
    }

    /// @inheritdoc IStabilityPoolFacet
    function setCompoundingPercentage(
        uint256 newPercentage
    ) external onlyAdmin {
        LibStabilityPool.setCompoundingPercentage(newPercentage);
    }

    /// @inheritdoc IStabilityPoolFacet
    function toggleStabilityPool() external onlyAdmin {
        LibStabilityPool.toggleStabilityPool();
    }

    /// @notice Allows the contract to receive ETH (from Stability Pool rewards)
    receive() external payable {}
}
