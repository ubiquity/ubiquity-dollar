// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IStaking} from "../interfaces/IStaking.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";
import {LibStaking} from "../libraries/LibStaking.sol";

/**
 * @notice Ubiquity staking facet
 */
contract StakingFacet is IStaking, Modifiers {
    //=====================
    // Views
    //=====================

    /// @inheritdoc IStaking
    function getPendingStakingRewards(
        uint256 poolId,
        address user
    ) external view returns (uint256) {
        return LibStaking.getPendingStakingRewards(poolId, user);
    }

    /// @inheritdoc IStaking
    function getStakingMultiplier(
        uint256 from,
        uint256 to
    ) external view returns (uint256) {
        return LibStaking.getStakingMultiplier(from, to);
    }

    /// @inheritdoc IStaking
    function getStakingSettings()
        external
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return LibStaking.getStakingSettings();
    }

    /// @inheritdoc IStaking
    function getStakingUserInfo(
        uint256 poolId,
        address user
    ) external view returns (LibStaking.UserInfo memory) {
        return LibStaking.getStakingUserInfo(poolId, user);
    }

    /// @inheritdoc IStaking
    function getStakingPoolInfo(
        uint256 poolId
    ) external view returns (LibStaking.PoolInfo memory) {
        return LibStaking.getStakingPoolInfo(poolId);
    }

    /// @inheritdoc IStaking
    function getStakingPoolsLength() external view returns (uint256) {
        return LibStaking.getStakingPoolsLength();
    }

    //==================
    // Public methods
    //==================

    /// @inheritdoc IStaking
    function massUpdateStakingPools(uint256[] memory poolIdsToUpdate) external {
        LibStaking.massUpdateStakingPools(poolIdsToUpdate);
    }

    /// @inheritdoc IStaking
    function stake(uint256 poolId, uint256 amount) external {
        LibStaking.stake(poolId, amount);
    }

    /// @inheritdoc IStaking
    function unstake(uint256 poolId, uint256 amount) external {
        LibStaking.unstake(poolId, amount);
    }

    /// @inheritdoc IStaking
    function updateStakingPool(uint256 poolId) external {
        LibStaking.updateStakingPool(poolId);
    }

    //======================
    // Restricted methods
    //======================

    /// @inheritdoc IStaking
    function createStakingPool(
        uint256 allocationPoints,
        IERC20 lpToken,
        uint256[] memory poolIdsToUpdate
    ) external onlyAdmin {
        LibStaking.createStakingPool(
            allocationPoints,
            lpToken,
            poolIdsToUpdate
        );
    }

    /// @inheritdoc IStaking
    function setGovernanceBonusEndBlock(
        uint256 newGovernanceBonusEndBlock
    ) external onlyAdmin {
        LibStaking.setGovernanceBonusEndBlock(newGovernanceBonusEndBlock);
    }

    /// @inheritdoc IStaking
    function setGovernanceBonusMultiplier(
        uint256 newGovernanceBonusMultiplier
    ) external onlyAdmin {
        LibStaking.setGovernanceBonusMultiplier(newGovernanceBonusMultiplier);
    }

    /// @inheritdoc IStaking
    function setGovernancePerBlock(
        uint256 newGovernancePerBlock
    ) external onlyAdmin {
        LibStaking.setGovernancePerBlock(newGovernancePerBlock);
    }

    /// @inheritdoc IStaking
    function setGovernanceTreasuryDivider(
        uint256 newGovernanceTreasuryDivider
    ) external onlyAdmin {
        LibStaking.setGovernanceTreasuryDivider(newGovernanceTreasuryDivider);
    }

    /// @inheritdoc IStaking
    function setStakingRewardToken(address newRewardToken) external onlyAdmin {
        LibStaking.setStakingRewardToken(newRewardToken);
    }

    /// @inheritdoc IStaking
    function setStakingStartBlock(uint256 newStartBlock) external onlyAdmin {
        LibStaking.setStakingStartBlock(newStartBlock);
    }

    /// @inheritdoc IStaking
    function updateStakingPool(
        uint256 poolId,
        uint256 allocationPoints,
        uint256[] memory poolIdsToUpdate
    ) external onlyAdmin {
        LibStaking.updateStakingPool(poolId, allocationPoints, poolIdsToUpdate);
    }
}
