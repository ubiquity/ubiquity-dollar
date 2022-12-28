// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {LibStaking} from "../libraries/LibStaking.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

contract StakingFacet is Modifiers {
    /// @dev dollarPriceReset remove Ubiquity Dollar unilaterally from the curve LP share sitting inside
    ///      the staking contract and send the Ubiquity Dollar received to the treasury.
    ///      This will have the immediate effect of pushing the Ubiquity Dollar price HIGHER
    /// @param amount of LP token to be removed for Ubiquity Dollar
    /// @notice it will remove one coin only from the curve LP share sitting in the staking contract
    function dollarPriceReset(uint256 amount) external onlyStakingManager {
        LibStaking.dollarPriceReset(amount);
    }

    /// @dev crvPriceReset remove 3CRV unilaterally from the curve LP share sitting inside
    ///      the staking contract and send the 3CRV received to the treasury
    ///      This will have the immediate effect of pushing the Ubiquity Dollar price LOWER
    /// @param amount of LP token to be removed for 3CRV tokens
    /// @notice it will remove one coin only from the curve LP share sitting in the staking contract
    function crvPriceReset(uint256 amount) external onlyStakingManager {
        LibStaking.crvPriceReset(amount);
    }

    function setStakingDiscountMultiplier(uint256 _stakingDiscountMultiplier)
        external
        onlyStakingManager
    {
        LibStaking.setStakingDiscountMultiplier(_stakingDiscountMultiplier);
    }

    function setBlockCountInAWeek(uint256 _blockCountInAWeek)
        external
        onlyStakingManager
    {
        LibStaking.setBlockCountInAWeek(_blockCountInAWeek);
    }

    /// @dev deposit UbiquityDollar-3CRV LP tokens for a duration to receive staking shares
    /// @param _lpsAmount of LP token to send
    /// @param _weeks during lp token will be held
    /// @notice weeks act as a multiplier for the amount of staking shares to be received
    function deposit(uint256 _lpsAmount, uint256 _weeks)
        external
        whenNotPaused
        returns (uint256 _id)
    {
        return LibStaking.deposit(_lpsAmount, _weeks);
    }

    /// @dev Add an amount of UbiquityDollar-3CRV LP tokens
    /// @param _amount of LP token to deposit
    /// @param _id staking shares id
    /// @param _weeks during lp token will be held
    /// @notice staking shares are ERC1155 (aka NFT) because they have an expiration date
    function addLiquidity(
        uint256 _amount,
        uint256 _id,
        uint256 _weeks
    ) external whenNotPaused {
        LibStaking.addLiquidity(_amount, _id, _weeks);
    }

    /// @dev Remove an amount of UbiquityDollar-3CRV LP tokens
    /// @param _amount of LP token deposited when _id was created to be withdrawn
    /// @param _id staking shares id
    /// @notice staking shares are ERC1155 (aka NFT) because they have an expiration date
    function removeLiquidity(uint256 _amount, uint256 _id)
        external
        whenNotPaused
    {
        LibStaking.removeLiquidity(_amount, _id);
    }

    // View function to see pending lpRewards on frontend.
    function pendingLpRewards(uint256 _id) external view returns (uint256) {
        return LibStaking.pendingLpRewards(_id);
    }

    /// @dev return the amount of Lp token rewards an amount of shares entitled
    /// @param amount of staking shares
    /// @param lpRewardDebt lp rewards that has already been distributed
    function lpRewardForShares(uint256 amount, uint256 lpRewardDebt)
        external
        view
        returns (uint256 pendingLpReward)
    {
        return LibStaking.lpRewardForShares(amount, lpRewardDebt);
    }

    function currentShareValue() external view returns (uint256 priceShare) {
        priceShare = LibStaking.currentShareValue();
    }
}
