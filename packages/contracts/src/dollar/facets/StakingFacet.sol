// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {LibStaking} from "../libraries/LibStaking.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

import {IStaking} from "../../dollar/interfaces/IStaking.sol";

/// @notice Staking facet
contract StakingFacet is Modifiers, IStaking {
    /**
     * @notice Removes Ubiquity Dollar unilaterally from the curve LP share sitting inside
     * the staking contract and sends the Ubiquity Dollar received to the treasury. This will
     * have the immediate effect of pushing the Ubiquity Dollar price HIGHER
     * @notice It will remove one coin only from the curve LP share sitting in the staking contract
     * @param amount Amount of LP token to be removed for Ubiquity Dollar
     */
    function dollarPriceReset(uint256 amount) external onlyStakingManager {
        LibStaking.dollarPriceReset(amount);
    }

    /**
     * @notice Remove 3CRV unilaterally from the curve LP share sitting inside
     * the staking contract and send the 3CRV received to the treasury. This will
     * have the immediate effect of pushing the Ubiquity Dollar price LOWER.
     * @notice It will remove one coin only from the curve LP share sitting in the staking contract
     * @param amount Amount of LP token to be removed for 3CRV tokens
     */
    function crvPriceReset(uint256 amount) external onlyStakingManager {
        LibStaking.crvPriceReset(amount);
    }

    /**
     * @notice Sets staking discount multiplier
     * @param _stakingDiscountMultiplier New staking discount multiplier
     */
    function setStakingDiscountMultiplier(
        uint256 _stakingDiscountMultiplier
    ) external onlyStakingManager {
        LibStaking.setStakingDiscountMultiplier(_stakingDiscountMultiplier);
    }

    /**
     * @notice Returns staking discount multiplier
     * @return Staking discount multiplier
     */
    function stakingDiscountMultiplier() external view returns (uint256) {
        return LibStaking.stakingDiscountMultiplier();
    }

    /**
     * @notice Returns number of blocks in a week
     * @return Number of blocks in a week
     */
    function blockCountInAWeek() external view returns (uint256) {
        return LibStaking.blockCountInAWeek();
    }

    /**
     * @notice Sets number of blocks in a week
     * @param _blockCountInAWeek Number of blocks in a week
     */
    function setBlockCountInAWeek(
        uint256 _blockCountInAWeek
    ) external onlyStakingManager {
        LibStaking.setBlockCountInAWeek(_blockCountInAWeek);
    }

    /**
     * @notice Deposits UbiquityDollar-3CRV LP tokens for a duration to receive staking shares
     * @notice Weeks act as a multiplier for the amount of staking shares to be received
     * @param _lpsAmount Amount of LP tokens to send
     * @param _weeks Number of weeks during which LP tokens will be held
     * @return _id Staking share id
     */
    function deposit(
        uint256 _lpsAmount,
        uint256 _weeks
    ) external whenNotPaused returns (uint256 _id) {
        return LibStaking.deposit(_lpsAmount, _weeks);
    }

    /**
     * @notice Adds an amount of UbiquityDollar-3CRV LP tokens
     * @notice Staking shares are ERC1155 (aka NFT) because they have an expiration date
     * @param _amount Amount of LP token to deposit
     * @param _id Staking share id
     * @param _weeks Number of weeks during which LP tokens will be held
     */
    function addLiquidity(
        uint256 _amount,
        uint256 _id,
        uint256 _weeks
    ) external whenNotPaused {
        LibStaking.addLiquidity(_amount, _id, _weeks);
    }

    /**
     * @notice Removes an amount of UbiquityDollar-3CRV LP tokens
     * @notice Staking shares are ERC1155 (aka NFT) because they have an expiration date
     * @param _amount Amount of LP token deposited when `_id` was created to be withdrawn
     * @param _id Staking share id
     */
    function removeLiquidity(
        uint256 _amount,
        uint256 _id
    ) external whenNotPaused {
        LibStaking.removeLiquidity(_amount, _id);
    }

    /**
     * @notice View function to see pending LP rewards on frontend
     * @param _id Staking share id
     * @return Amount of LP rewards
     */
    function pendingLpRewards(uint256 _id) external view returns (uint256) {
        return LibStaking.pendingLpRewards(_id);
    }

    /**
     * @notice Returns the amount of LP token rewards an amount of shares entitled
     * @param amount Amount of staking shares
     * @param lpRewardDebt Amount of LP rewards that have already been distributed
     * @return pendingLpReward Amount of pending LP rewards
     */
    function lpRewardForShares(
        uint256 amount,
        uint256 lpRewardDebt
    ) external view returns (uint256 pendingLpReward) {
        return LibStaking.lpRewardForShares(amount, lpRewardDebt);
    }

    /**
     * @notice Returns current share price
     * @return priceShare Share price
     */
    function currentShareValue() external view returns (uint256 priceShare) {
        priceShare = LibStaking.currentShareValue();
    }
}
