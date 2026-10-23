// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import {IStabilityPoolFacet} from "../interfaces/IStabilityPoolFacet.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";
import {LibStabilityPool} from "../libraries/LibStabilityPool.sol";

/**
 * @notice Stability Pool Facet for Liquity V1 integration
 * @dev Integrates with the Liquity V1 Stability Pool to earn ETH/LQTY yields
 *      on LUSD collateral. Auto-deposit on mint, withdraw on redeem, harvest
 *      rewards to treasury.
 *
 * Deployment: Add via diamondCut with the facet's function selectors.
 */
contract StabilityPoolFacet is IStabilityPoolFacet, Modifiers {
    using LibStabilityPool for bytes32;

    //=====================
    // Views
    //=====================

    /// @inheritdoc IStabilityPoolFacet
    function stabilityPoolAddress() external view returns (address) {
        return LibStabilityPool.stabilityPoolStorage().stabilityPool;
    }

    /// @inheritdoc IStabilityPoolFacet
    function totalPrincipalInPool() external view returns (uint256) {
        return LibStabilityPool.stabilityPoolStorage().totalPrincipalInPool;
    }

    /// @inheritdoc IStabilityPoolFacet
    function rewardThreshold() external view returns (uint256) {
        return LibStabilityPool.stabilityPoolStorage().rewardThreshold;
    }

    /// @inheritdoc IStabilityPoolFacet
    function spTreasuryAddress() external view returns (address) {
        return LibStabilityPool.stabilityPoolStorage().treasury;
    }

    /// @inheritdoc IStabilityPoolFacet
    function getDepositedLUSD() external view returns (uint256) {
        return LibStabilityPool._getDepositedLUSD();
    }

    /// @inheritdoc IStabilityPoolFacet
    function getPendingETHReward() external view returns (uint256) {
        return LibStabilityPool._getPendingETHReward();
    }

    /// @inheritdoc IStabilityPoolFacet
    function getPendingLQTYReward() external view returns (uint256) {
        return LibStabilityPool._getPendingLQTYReward();
    }

    //====================
    // Public functions
    //====================

    /// @inheritdoc IStabilityPoolFacet
    function depositToPool(uint256 amount) external nonReentrant {
        LibStabilityPool._depositToPool(amount);
    }

    /// @inheritdoc IStabilityPoolFacet
    function withdrawFromPool(uint256 amount) external nonReentrant {
        LibStabilityPool._withdrawFromPool(amount);
    }

    /// @inheritdoc IStabilityPoolFacet
    function harvestRewards() external nonReentrant {
        LibStabilityPool._harvestRewards();
    }

    //========================
    // Restricted functions
    //========================

    /// @inheritdoc IStabilityPoolFacet
    function setStabilityPoolAddress(
        address _stabilityPool
    ) external onlyAdmin {
        LibStabilityPool._setStabilityPoolAddress(_stabilityPool);
    }

    /// @inheritdoc IStabilityPoolFacet
    function setRewardThreshold(uint256 _threshold) external onlyAdmin {
        LibStabilityPool._setRewardThreshold(_threshold);
    }

    /// @inheritdoc IStabilityPoolFacet
    function setSpTreasuryAddress(address _treasury) external onlyAdmin {
        LibStabilityPool._setTreasuryAddress(_treasury);
    }
}
