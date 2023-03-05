// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "../../src/dollar/StakingFormulas.sol";
import "../../src/dollar/StakingShare.sol";
import "abdk/ABDKMathQuad.sol";

import "../helpers/LocalTestHelper.sol";

contract StakingFormulasTest is LocalTestHelper {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    StakingFormulas stakingFormulas;

    function setUp() public override {
        stakingFormulas = new StakingFormulas();
    }

    function testSharesForLP_ShouldReturn_CorrectValue() public {
        StakingShare.Stake memory _stake = StakingShare.Stake({
            // address of the minter
            minter: address(0x11111),
            // lp amount deposited by the user
            lpFirstDeposited: 0,
            creationBlock: 100,
            // lp that were already there when created
            lpRewardDebt: 0,
            endBlock: 1000,
            // lp remaining for a user
            lpAmount: 100
        });

        uint256[2] memory _shareInfo = [uint256(100), uint256(100)];
        uint256 _amount = 10;

        assertEq(stakingFormulas.sharesForLP(_stake, _shareInfo, _amount), 10);
    }

    function testLpRewardsRemoveLiquidityNormalization_ShouldReturnCorrectValue(
        StakingShare.Stake memory _stake,
        uint256[2] memory _shareInfo,
        uint256 _amount
    ) public {
        assertEq(
            stakingFormulas.lpRewardsRemoveLiquidityNormalization(
                _stake,
                _shareInfo,
                _amount
            ),
            _amount
        );
    }

    function testLpRewardsAddLiquidityNormalization_ShouldReturnCorrectValue(
        StakingShare.Stake memory _stake,
        uint256[2] memory _shareInfo,
        uint256 _amount
    ) public {
        assertEq(
            stakingFormulas.lpRewardsAddLiquidityNormalization(
                _stake,
                _shareInfo,
                _amount
            ),
            _amount
        );
    }

    function testCorrectedAmountToWithdraw_ShouldReturnAmount() public {
        uint256 _totalLpDeposited = 10000;
        uint256 _stakingLpBalance = 20000;
        uint256 _amount = 100;
        assertEq(
            stakingFormulas.correctedAmountToWithdraw(
                _totalLpDeposited,
                _stakingLpBalance,
                _amount
            ),
            100
        );
    }

    function testCorrectedAmountToWithdraw_ShouldCalculateSharedAmount()
        public
    {
        uint256 _totalLpDeposited = 10000;
        uint256 _stakingLpBalance = 5000;
        uint256 _amount = 100;
        assertEq(
            stakingFormulas.correctedAmountToWithdraw(
                _totalLpDeposited,
                _stakingLpBalance,
                _amount
            ),
            50
        );
    }
}
