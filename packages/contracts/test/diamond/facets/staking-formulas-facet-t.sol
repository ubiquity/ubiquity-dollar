// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../diamond-test-setup.sol";
import "abdk/ABDKMathQuad.sol";
import {StakingShare} from "../../../src/dollar/core/staking-share.sol";

contract StakingFormulasFacetTest is DiamondSetup {
    using ABDKMathQuad for uint256;
    using ABDKMathQuad for bytes16;

    function setUp() public virtual override {
        super.setUp();
    }

    function test_sharesForLP() public {
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

        assertEq(
            IStakingFormulasFacet.sharesForLP(_stake, _shareInfo, _amount),
            10
        );
    }

    function test_lpRewardsRemoveLiquidityNormalization(
        StakingShare.Stake memory _stake,
        uint256[2] memory _shareInfo,
        uint256 _amount
    ) public {
        assertEq(
            IStakingFormulasFacet.lpRewardsRemoveLiquidityNormalization(
                _stake,
                _shareInfo,
                _amount
            ),
            _amount
        );
    }

    function test_lpRewardsAddLiquidityNormalization(
        StakingShare.Stake memory _stake,
        uint256[2] memory _shareInfo,
        uint256 _amount
    ) public {
        assertEq(
            IStakingFormulasFacet.lpRewardsAddLiquidityNormalization(
                _stake,
                _shareInfo,
                _amount
            ),
            _amount
        );
    }

    function test_correctedAmountToWithdraw_returnAmount() public {
        uint256 _totalLpDeposited = 10000;
        uint256 _stakingLpBalance = 20000;
        uint256 _amount = 100;
        assertEq(
            IStakingFormulasFacet.correctedAmountToWithdraw(
                _totalLpDeposited,
                _stakingLpBalance,
                _amount
            ),
            100
        );
    }

    function test_correctedAmountToWithdraw_calcSharedAmount() public {
        uint256 _totalLpDeposited = 10000;
        uint256 _stakingLpBalance = 5000;
        uint256 _amount = 100;
        assertEq(
            IStakingFormulasFacet.correctedAmountToWithdraw(
                _totalLpDeposited,
                _stakingLpBalance,
                _amount
            ),
            50
        );
    }

    function testDurationMultiply_ShouldReturnAmount() public {
        uint256 amount = IStakingFormulasFacet.durationMultiply(
            100 ether,
            1,
            1000000 gwei
        );
        assertEq(amount, 100100000000000000000);
    }
}
