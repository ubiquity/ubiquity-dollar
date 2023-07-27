// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {StakingShare} from "../core/StakingShare.sol";

/// @notice Interface for staking formulas
interface IUbiquityFormulas {
    /**
     * @notice Formula duration multiply
     * @notice `_shares = (1 + _multiplier * _weeks^3/2) * _uLP`
     * @notice `D32 = D^3/2`
     * @notice `S = m * D32 * A + A`
     * @param _uLP Amount of LP tokens
     * @param _weeks Minimum duration of staking period
     * @param _multiplier Staking discount multiplier = 0.0001
     * @return _shares Amount of shares
     */
    function durationMultiply(
        uint256 _uLP,
        uint256 _weeks,
        uint256 _multiplier
    ) external pure returns (uint256 _shares);

    /**
     * @notice Formula to calculate the corrected amount to withdraw based on the proportion of
     * LP deposited against actual LP tokens in the staking contract
     * @notice `corrected_amount = amount * (stakingLpBalance / totalLpDeposited)`
     * @notice If there is more or the same amount of LP than deposited then do nothing
     * @param _totalLpDeposited Total amount of LP deposited by users
     * @param _stakingLpBalance Actual staking contract LP tokens balance minus LP rewards
     * @param _amount Amount of LP tokens
     * @return Amount of LP tokens to redeem
     */
    function correctedAmountToWithdraw(
        uint256 _totalLpDeposited,
        uint256 _stakingLpBalance,
        uint256 _amount
    ) external pure returns (uint256);

    /**
     * @notice Formula may add a decreasing rewards if locking end is near when adding liquidity
     * @notice `rewards = _amount`
     * @param _stake Stake info of staking share
     * @param _shareInfo Array of share amounts
     * @param _amount Amount of LP tokens
     * @return Amount of LP rewards
     */
    function lpRewardsAddLiquidityNormalization(
        StakingShare.Stake memory _stake,
        uint256[2] memory _shareInfo,
        uint256 _amount
    ) external pure returns (uint256);

    /**
     * @notice Formula may add a decreasing rewards if locking end is near when removing liquidity
     * @notice `rewards = _amount`
     * @param _stake Stake info of staking share
     * @param _shareInfo Array of share amounts
     * @param _amount Amount of LP tokens
     * @return Amount of LP rewards
     */
    function lpRewardsRemoveLiquidityNormalization(
        StakingShare.Stake memory _stake,
        uint256[2] memory _shareInfo,
        uint256 _amount
    ) external pure returns (uint256);

    /**
     * @notice Formula of governance rights corresponding to a staking shares LP amount
     * @notice Used on removing liquidity from staking
     * @notice `shares = (stake.shares * _amount)  / stake.lpAmount`
     * @param _stake Stake info of staking share
     * @param _shareInfo Array of share amounts
     * @param _amount Amount of LP tokens
     * @return _uLP Amount of shares
     */
    function sharesForLP(
        StakingShare.Stake memory _stake,
        uint256[2] memory _shareInfo,
        uint256 _amount
    ) external pure returns (uint256 _uLP);
}
