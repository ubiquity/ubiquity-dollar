// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "./StakingShare.sol";
import "abdk-libraries-solidity/ABDKMathQuad.sol";

contract StakingFormulas {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    uint256 public constant ONE = uint256(1 ether); //   18 decimals

    /// @dev formula Governance Rights corresponding to a staking shares LP amount
    /// @param _stake , staking share
    /// @param _amount , amount of LP tokens
    /// @notice shares = (stake.shares * _amount )  / stake.lpAmount ;
    function sharesForLP(
        StakingShare.Stake memory _stake,
        uint256[2] memory _shareInfo,
        uint256 _amount
    ) public pure returns (uint256 _uLP) {
        bytes16 a = _shareInfo[0].fromUInt(); // shares amount
        bytes16 v = _amount.fromUInt();
        bytes16 t = _stake.lpAmount.fromUInt();

        _uLP = a.mul(v).div(t).toUInt();
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
    ) public pure returns (uint256) {
        return _amount;
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
    ) public pure returns (uint256) {
        return _amount;
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
    ) public pure returns (uint256) {
        if (_stakingLpBalance < _totalLpDeposited && _stakingLpBalance > 0) {
            // if there is less LP token inside the staking contract that what have been deposited
            // we have to reduce proportionally the lp amount to withdraw
            return _amount.fromUInt().mul(_stakingLpBalance.fromUInt()).div(
                _totalLpDeposited.fromUInt()
            ).toUInt();
        }
        return _amount;
    }
}
