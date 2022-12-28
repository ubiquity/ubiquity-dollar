// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {LibStakingFormulas} from "../libraries/LibStakingFormulas.sol";
import {StakingShare} from "../../dollar/StakingShare.sol";

contract StakingFormulasFacet {
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
}
