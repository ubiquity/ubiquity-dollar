// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {StakingShare} from "../core/staking-share.sol";

interface IUbiquityFormulas {
    function durationMultiply(
        uint256 _uLP,
        uint256 _weeks,
        uint256 _multiplier
    ) external pure returns (uint256 _shares);

    function correctedAmountToWithdraw(
        uint256 _totalLpDeposited,
        uint256 _stakingLpBalance,
        uint256 _amount
    ) external pure returns (uint256);

    function lpRewardsAddLiquidityNormalization(
        StakingShare.Stake memory _stake,
        uint256[2] memory _shareInfo,
        uint256 _amount
    ) external pure returns (uint256);

    function lpRewardsRemoveLiquidityNormalization(
        StakingShare.Stake memory _stake,
        uint256[2] memory _shareInfo,
        uint256 _amount
    ) external pure returns (uint256);

    function sharesForLP(
        StakingShare.Stake memory _stake,
        uint256[2] memory _shareInfo,
        uint256 _amount
    ) external pure returns (uint256 _uLP);
}
