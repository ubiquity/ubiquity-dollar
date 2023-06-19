// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {LibStakingFormulas} from "../libraries/LibStakingFormulas.sol";
import {StakingShare} from "../core/StakingShare.sol";
import "../interfaces/IUbiquityFormulas.sol";

contract StakingFormulasFacet is IUbiquityFormulas {
    /// @dev formula Governance Rights corresponding to a staking shares LP amount
    /// @param _stake , staking share
    /// @param _amount , amount of LP tokens
    /// @notice shares = (stake.shares * _amount )  / stake.lpAmount ;
    function sharesForLP(
        StakingShare.Stake memory _stake,
        uint256[2] memory _shareInfo,
        uint256 _amount
    ) external pure returns (uint256 _uLP) {
        return LibStakingFormulas.sharesForLP(_stake, _shareInfo, _amount);
    }

    /// @dev formula may add a decreasing rewards if locking end is near when removing liquidity
    /// @param _stake , staking share
    /// @param _amount , amount of LP tokens
    /// @notice rewards = _amount;
    // solhint-disable-block  no-unused-vars
    /* solhint-disable no-unused-vars */
    function lpRewardsRemoveLiquidityNormalization(
        StakingShare.Stake memory _stake,
        uint256[2] memory _shareInfo,
        uint256 _amount
    ) external pure returns (uint256) {
        return
            LibStakingFormulas.lpRewardsRemoveLiquidityNormalization(
                _stake,
                _shareInfo,
                _amount
            );
    }

    /* solhint-enable no-unused-vars */
    /// @dev formula may add a decreasing rewards if locking end is near when adding liquidity
    /// @param _stake , staking share
    /// @param _amount , amount of LP tokens
    /// @notice rewards = _amount;
    // solhint-disable-block  no-unused-vars
    /* solhint-disable no-unused-vars */
    function lpRewardsAddLiquidityNormalization(
        StakingShare.Stake memory _stake,
        uint256[2] memory _shareInfo,
        uint256 _amount
    ) external pure returns (uint256) {
        return
            LibStakingFormulas.lpRewardsAddLiquidityNormalization(
                _stake,
                _shareInfo,
                _amount
            );
    }

    /* solhint-enable no-unused-vars */

    /// @dev formula to calculate the corrected amount to withdraw based on the proportion of
    ///      lp deposited against actual LP token on the staking contract
    /// @param _totalLpDeposited , Total amount of LP deposited by users
    /// @param _stakingLpBalance , actual staking contract LP tokens balance minus lp rewards
    /// @param _amount , amount of LP tokens
    /// @notice corrected_amount = amount * ( stakingLpBalance / totalLpDeposited)
    ///         if there is more or the same amount of LP than deposited then do nothing
    function correctedAmountToWithdraw(
        uint256 _totalLpDeposited,
        uint256 _stakingLpBalance,
        uint256 _amount
    ) external pure returns (uint256) {
        return
            LibStakingFormulas.correctedAmountToWithdraw(
                _totalLpDeposited,
                _stakingLpBalance,
                _amount
            );
    }

    /// @dev formula duration multiply
    /// @param _uLP , amount of LP tokens
    /// @param _weeks , minimum duration of staking period
    /// @param _multiplier , staking discount multiplier = 0.0001
    /// @return _shares , amount of shares
    /// @notice _shares = (1 + _multiplier * _weeks^3/2) * _uLP
    //          D32 = D^3/2
    //          S = m * D32 * A + A
    function durationMultiply(
        uint256 _uLP,
        uint256 _weeks,
        uint256 _multiplier
    ) external pure returns (uint256 _shares) {
        return LibStakingFormulas.durationMultiply(_uLP, _weeks, _multiplier);
    }
}
