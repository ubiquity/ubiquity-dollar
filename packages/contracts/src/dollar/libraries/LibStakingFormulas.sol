// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {StakingShare} from "../../../src/dollar/core/StakingShare.sol";
import "abdk/ABDKMathQuad.sol";
import "./Constants.sol";

/// @notice Library for staking formulas
library LibStakingFormulas {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

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
    ) internal pure returns (uint256) {
        if (_stakingLpBalance < _totalLpDeposited && _stakingLpBalance > 0) {
            // if there is less LP token inside the staking contract that what have been deposited
            // we have to reduce proportionally the lp amount to withdraw
            return
                _amount
                    .fromUInt()
                    .mul(_stakingLpBalance.fromUInt())
                    .div(_totalLpDeposited.fromUInt())
                    .toUInt();
        }
        return _amount;
    }

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
    ) internal pure returns (uint256 _uLP) {
        bytes16 a = _shareInfo[0].fromUInt(); // shares amount
        bytes16 v = _amount.fromUInt();
        bytes16 t = _stake.lpAmount.fromUInt();

        _uLP = a.mul(v).div(t).toUInt();
    }

    /**
     * @notice Formula may add a decreasing rewards if locking end is near when removing liquidity
     * @notice `rewards = _amount`
     * @param _amount Amount of LP tokens
     * @return Amount of LP rewards
     */
    function lpRewardsRemoveLiquidityNormalization(
        StakingShare.Stake memory /* _stake */,
        uint256[2] memory /* _shareInfo */,
        uint256 _amount
    ) internal pure returns (uint256) {
        return _amount;
    }

    /**
     * @notice Formula may add a decreasing rewards if locking end is near when adding liquidity
     * @notice `rewards = _amount`
     * @param _amount Amount of LP tokens
     * @return Amount of LP rewards
     */
    function lpRewardsAddLiquidityNormalization(
        StakingShare.Stake memory /* _stake */,
        uint256[2] memory /* _shareInfo */,
        uint256 _amount
    ) internal pure returns (uint256) {
        return _amount;
    }

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
    ) internal pure returns (uint256 _shares) {
        bytes16 unit = uint256(1 ether).fromUInt();
        bytes16 d = _weeks.fromUInt();
        bytes16 d32 = (d.mul(d).mul(d)).sqrt();
        bytes16 a = _uLP.fromUInt();

        _shares = _multiplier
            .fromUInt()
            .mul(d32)
            .mul(a)
            .div(unit)
            .add(a)
            .toUInt();
    }

    /**
     * @notice Formula staking price
     * @notice
     * ```
     * IF _totalStakingShares = 0
     *   priceBOND = TARGET_PRICE
     * ELSE
     *   priceBOND = totalLP / totalShares * TARGET_PRICE
     * R = T == 0 ? 1 : LP / S
     * P = R * T
     * ```
     * @param _totalULP Total LP tokens
     * @param _totalStakingShares Total staking shares
     * @param _targetPrice Target Ubiquity Dollar price
     * @return _stakingPrice Staking share price
     */
    function bondPrice(
        uint256 _totalULP,
        uint256 _totalStakingShares,
        uint256 _targetPrice
    ) internal pure returns (uint256 _stakingPrice) {
        bytes16 lp = _totalULP.fromUInt();
        bytes16 s = _totalStakingShares.fromUInt();
        bytes16 r = _totalStakingShares == 0
            ? uint256(1).fromUInt()
            : lp.div(s);
        bytes16 t = _targetPrice.fromUInt();

        _stakingPrice = r.mul(t).toUInt();
    }

    /**
     * @notice Formula Governance token multiply
     * @notice
     * ```
     * new_multiplier = multiplier * (1.05 / (1 + abs(1 - price)))
     * nM = M * C / A
     * A = (1 + abs(1 - P)))
     * 5 >= multiplier >= 0.2
     * ```
     * @param _multiplier Initial Governance token min multiplier
     * @param _price Current share price
     * @return _newMultiplier New Governance token min multiplier
     */
    function governanceMultiply(
        uint256 _multiplier,
        uint256 _price
    ) internal pure returns (uint256 _newMultiplier) {
        bytes16 m = _multiplier.fromUInt();
        bytes16 p = _price.fromUInt();
        bytes16 c = uint256(105 * 1e16).fromUInt(); // 1.05
        bytes16 u = uint256(1e18).fromUInt(); // 1
        bytes16 a = u.add(u.sub(p).abs()); // 1 + abs( 1 - P )

        _newMultiplier = m.mul(c).div(a).toUInt(); // nM = M * C / A

        // 5 >= multiplier >= 0.2
        if (_newMultiplier > 5e18 || _newMultiplier < 2e17) {
            _newMultiplier = _multiplier;
        }
    }
}
