// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/console2.sol";
import {DiamondTestSetup} from "../../../diamond/DiamondTestSetup.sol";
import {UbiquityAlgorithmicDollarManager} from "../../../../src/deprecated/UbiquityAlgorithmicDollarManager.sol";
import {UbiquityGovernance} from "../../../../src/deprecated/UbiquityGovernance.sol";
import {LibStaking} from "../../../../src/dollar/libraries/LibStaking.sol";
import {MockERC20} from "../../../../src/dollar/mocks/MockERC20.sol";

contract StakingFacetFuzzTest is DiamondTestSetup {
    UbiquityAlgorithmicDollarManager dollarManager;
    UbiquityGovernance rewardToken;
    MockERC20 stakeToken;

    address user = makeAddr("user");
    address user2 = makeAddr("user2");

    function setUp() public override {
        super.setUp();

        vm.prank(owner);
        dollarManager = new UbiquityAlgorithmicDollarManager(owner);

        vm.prank(owner);
        rewardToken = new UbiquityGovernance(address(dollarManager));

        stakeToken = new MockERC20("STK", "STK", 18);

        // staking setup
        vm.startPrank(admin);
        stakingFacet.setGovernancePerBlock(1 ether);
        stakingFacet.setGovernanceTreasuryDivider(5);
        stakingFacet.setStakingRewardToken(address(rewardToken));
        stakingFacet.setStakingStartBlock(block.number);
        vm.stopPrank();

        // owner grants diamond the "UBQ_MINTER_ROLE"
        // NOTICE: in production environment the diamond contract already has the "UBQ_MINTER_ROLE" role
        vm.prank(owner);
        dollarManager.grantRole(keccak256("UBQ_MINTER_ROLE"), address(diamond));

        // admin creates a new staking pool
        vm.startPrank(admin);
        stakingFacet.createStakingPool(
            100, // allocation points
            stakeToken,
            getAvailablePoolIds() // array of pool ids to update
        );
        vm.stopPrank();

        // user approves diamond to spend STK tokens
        vm.prank(user);
        stakeToken.approve(address(diamond), type(uint256).max);

        // user2 approves diamond to spend STK tokens
        vm.prank(user2);
        stakeToken.approve(address(diamond), type(uint256).max);
    }

    function testCreateStakingPool_ShouldNotAffectRewardsCalculation(
        uint256 stakeAmount,
        uint256 blocksPassed,
        uint256 allocationPoints
    ) public {
        stakeAmount = bound(stakeAmount, 1, 100_000_000 ether);
        blocksPassed = bound(blocksPassed, 1, 2628000 * 10); // max 10 years
        allocationPoints = bound(allocationPoints, 1, 1000);

        // deploy stake token for 2nd pool
        MockERC20 stakeTokenLowDecimals = new MockERC20(
            "STL_LOW",
            "STK_LOW",
            6
        );

        // user approves diamond to spend STK_LOW tokens
        vm.prank(user);
        stakeTokenLowDecimals.approve(address(diamond), type(uint256).max);

        // user2 approves diamond to spend STK_LOW tokens
        vm.prank(user2);
        stakeTokenLowDecimals.approve(address(diamond), type(uint256).max);

        // admin creates 2nd pool
        vm.startPrank(admin);
        stakingFacet.createStakingPool(
            allocationPoints, // allocation points
            stakeTokenLowDecimals,
            getAvailablePoolIds() // array of pool ids to update
        );
        vm.stopPrank();

        // mint tokens to users
        stakeToken.mint(user, stakeAmount);
        stakeTokenLowDecimals.mint(user2, stakeAmount);

        // user stakes STK at time T1 in pool 0
        uint256 stakeBlockNumberUser = block.number;
        vm.prank(user);
        stakingFacet.stake(0, stakeAmount);

        // user2 stakes STK_LOW at time T2 in pool 1
        vm.roll(block.number + blocksPassed);
        uint256 stakeBlockNumberUser2 = block.number;
        vm.prank(user2);
        stakingFacet.stake(1, stakeAmount);

        // user unstakes STK from pool 0 and collects rewards at time T3
        vm.roll(block.number + blocksPassed);
        uint256 unstakeBlockNumberUser = block.number;
        vm.prank(user);
        stakingFacet.unstake(0, stakeAmount);

        // user2 unstakes STK_LOW from pool 1 and collects rewards at time T4
        vm.roll(block.number + blocksPassed);
        uint256 unstakeBlockNumberUser2 = block.number;
        vm.prank(user2);
        stakingFacet.unstake(1, stakeAmount);

        // assert calculations
        LibStaking.UserInfo memory userInfo = stakingFacet.getStakingUserInfo(
            0,
            user
        );
        LibStaking.UserInfo memory userInfo2 = stakingFacet.getStakingUserInfo(
            1,
            user2
        );
        LibStaking.PoolInfo memory poolInfo = stakingFacet.getStakingPoolInfo(
            0
        );
        LibStaking.PoolInfo memory poolInfo2 = stakingFacet.getStakingPoolInfo(
            1
        );
        assertEq(userInfo.amount, 0);
        assertEq(userInfo2.amount, 0);
        assertEq(poolInfo.amount, 0);
        assertEq(poolInfo2.amount, 0);
        assertEq(stakeToken.balanceOf(user), stakeAmount);
        assertEq(stakeTokenLowDecimals.balanceOf(user2), stakeAmount);
        assertEq(stakeToken.balanceOf(address(stakingFacet)), 0);
        assertEq(stakeTokenLowDecimals.balanceOf(address(stakingFacet)), 0);
        // rewards
        (
            ,
            ,
            ,
            uint256 governancePerBlock,
            ,
            ,
            uint256 totalAllocationPoints,

        ) = stakingFacet.getStakingSettings();
        uint256 expectedRewardsUser = ((unstakeBlockNumberUser -
            stakeBlockNumberUser) *
            governancePerBlock *
            poolInfo.allocationPoints) / totalAllocationPoints;
        uint256 expectedRewardsUser2 = ((unstakeBlockNumberUser2 -
            stakeBlockNumberUser2) *
            governancePerBlock *
            poolInfo2.allocationPoints) / totalAllocationPoints;
        assertApproxEqAbs(
            rewardToken.balanceOf(user),
            expectedRewardsUser,
            1e15
        );
        assertApproxEqAbs(
            rewardToken.balanceOf(user2),
            expectedRewardsUser2,
            1e15
        );
    }

    function testSetGovernanceBonusMultiplier_ShouldNotAffectRewardsCalculation(
        uint256 stakeAmount,
        uint256 blocksPassed,
        uint256 governanceBonusEndBlock,
        uint256 governanceBonusMultiplier
    ) public {
        stakeAmount = bound(stakeAmount, 1, 100_000_000 ether);
        blocksPassed = bound(blocksPassed, 1, 2628000 * 10); // max 10 years
        governanceBonusEndBlock = bound(
            governanceBonusEndBlock,
            1,
            2628000 * 10
        ); // max 10 years
        governanceBonusMultiplier = bound(governanceBonusMultiplier, 1, 1000);

        // admin sets governance bonus end block
        vm.prank(admin);
        stakingFacet.setGovernanceBonusEndBlock(governanceBonusEndBlock);

        // admin sets governance bonus multiplier
        vm.prank(admin);
        stakingFacet.setGovernanceBonusMultiplier(governanceBonusMultiplier);

        // mint X STK tokens to users
        stakeToken.mint(user, stakeAmount);
        stakeToken.mint(user2, stakeAmount);

        // user stakes STK at time T1
        uint256 stakeBlockNumberUser = block.number;
        vm.prank(user);
        stakingFacet.stake(0, stakeAmount);

        // user2 stakes STK at time T2
        vm.roll(block.number + blocksPassed);
        uint256 stakeBlockNumberUser2 = block.number;
        vm.prank(user2);
        stakingFacet.stake(0, stakeAmount);

        // user unstakes STK and collects rewards at time T3
        vm.roll(block.number + blocksPassed);
        uint256 unstakeBlockNumberUser = block.number;
        vm.prank(user);
        stakingFacet.unstake(0, stakeAmount);

        // user2 unstakes STK and collects rewards at time T4
        vm.roll(block.number + blocksPassed);
        uint256 unstakeBlockNumberUser2 = block.number;
        vm.prank(user2);
        stakingFacet.unstake(0, stakeAmount);

        // assert calculations
        LibStaking.UserInfo memory userInfo = stakingFacet.getStakingUserInfo(
            0,
            user
        );
        LibStaking.UserInfo memory userInfo2 = stakingFacet.getStakingUserInfo(
            0,
            user2
        );
        LibStaking.PoolInfo memory poolInfo = stakingFacet.getStakingPoolInfo(
            0
        );
        assertEq(userInfo.amount, 0);
        assertEq(userInfo2.amount, 0);
        assertEq(poolInfo.amount, 0);
        assertEq(stakeToken.balanceOf(user), stakeAmount);
        assertEq(stakeToken.balanceOf(user2), stakeAmount);
        assertEq(stakeToken.balanceOf(address(stakingFacet)), 0);
        // rewards
        (, , , uint256 governancePerBlock, , , , ) = stakingFacet
            .getStakingSettings();
        uint256 usersCount = 2;
        uint256 expectedRewardsUser = stakingFacet.getStakingMultiplier(
            stakeBlockNumberUser,
            stakeBlockNumberUser2
        ) *
            governancePerBlock +
            (stakingFacet.getStakingMultiplier(
                stakeBlockNumberUser2,
                unstakeBlockNumberUser
            ) * governancePerBlock) /
            usersCount;
        uint256 expectedRewardsUser2 = stakingFacet.getStakingMultiplier(
            unstakeBlockNumberUser,
            unstakeBlockNumberUser2
        ) *
            governancePerBlock +
            (stakingFacet.getStakingMultiplier(
                stakeBlockNumberUser2,
                unstakeBlockNumberUser
            ) * governancePerBlock) /
            usersCount;
        assertApproxEqAbs(
            rewardToken.balanceOf(user),
            expectedRewardsUser,
            1e15
        );
        assertApproxEqAbs(
            rewardToken.balanceOf(user2),
            expectedRewardsUser2,
            1e15
        );
    }

    // NOTICE: `admin` EOA is set to be a treasury address
    function testSetGovernanceTreasuryDivider_ShouldNotAffectRewardsCalculation(
        uint256 stakeAmount,
        uint256 blocksPassed,
        uint256 treasuryDivider
    ) public {
        stakeAmount = bound(stakeAmount, 1, 100_000_000 ether);
        blocksPassed = bound(blocksPassed, 1, 2628000 * 10); // max 10 years
        treasuryDivider = bound(treasuryDivider, 1, 100);

        // admin sets treasury divider
        vm.prank(admin);
        stakingFacet.setGovernanceTreasuryDivider(treasuryDivider);

        // mint X STK tokens to users
        stakeToken.mint(user, stakeAmount);
        stakeToken.mint(user2, stakeAmount);

        // user stakes STK at time T1
        uint256 stakeBlockNumberUser = block.number;
        vm.prank(user);
        stakingFacet.stake(0, stakeAmount);

        // user2 stakes STK at time T2
        vm.roll(block.number + blocksPassed);
        uint256 stakeBlockNumberUser2 = block.number;
        vm.prank(user2);
        stakingFacet.stake(0, stakeAmount);

        // user unstakes STK and collects rewards at time T3
        vm.roll(block.number + blocksPassed);
        uint256 unstakeBlockNumberUser = block.number;
        vm.prank(user);
        stakingFacet.unstake(0, stakeAmount);

        // user2 unstakes STK and collects rewards at time T4
        vm.roll(block.number + blocksPassed);
        uint256 unstakeBlockNumberUser2 = block.number;
        vm.prank(user2);
        stakingFacet.unstake(0, stakeAmount);

        // assert calculations
        (, , , uint256 governancePerBlock, , , , ) = stakingFacet
            .getStakingSettings();
        uint256 usersCount = 2;
        uint256 expectedRewardsUser = (stakeBlockNumberUser2 -
            stakeBlockNumberUser) *
            governancePerBlock +
            ((unstakeBlockNumberUser - stakeBlockNumberUser2) *
                governancePerBlock) /
            usersCount;
        uint256 expectedRewardsUser2 = (unstakeBlockNumberUser -
            stakeBlockNumberUser2) *
            governancePerBlock +
            ((unstakeBlockNumberUser2 - unstakeBlockNumberUser) *
                governancePerBlock) /
            usersCount;
        uint256 expectedRewardsTreasury = (expectedRewardsUser +
            expectedRewardsUser2) / treasuryDivider;
        assertApproxEqAbs(
            rewardToken.balanceOf(admin),
            expectedRewardsTreasury,
            1e15
        );
    }

    function testSetGovernancePerBlock_ShouldNotAffectRewardsCalculation(
        uint256 stakeAmount,
        uint256 blocksPassed,
        uint256 governancePerBlock
    ) public {
        stakeAmount = bound(stakeAmount, 1, 100_000_000 ether);
        blocksPassed = bound(blocksPassed, 1, 2628000 * 10); // max 10 years
        governancePerBlock = bound(governancePerBlock, 0.0001 ether, 100_000_000 ether);

        // admin sets governance per block
        vm.prank(admin);
        stakingFacet.setGovernancePerBlock(governancePerBlock);

        // mint X STK tokens to users
        stakeToken.mint(user, stakeAmount);
        stakeToken.mint(user2, stakeAmount);

        // user stakes STK at time T1
        uint256 stakeBlockNumberUser = block.number;
        vm.prank(user);
        stakingFacet.stake(0, stakeAmount);

        // user2 stakes STK at time T2
        vm.roll(block.number + blocksPassed);
        uint256 stakeBlockNumberUser2 = block.number;
        vm.prank(user2);
        stakingFacet.stake(0, stakeAmount);

        // user unstakes STK and collects rewards at time T3
        vm.roll(block.number + blocksPassed);
        uint256 unstakeBlockNumberUser = block.number;
        vm.prank(user);
        stakingFacet.unstake(0, stakeAmount);

        // user2 unstakes STK and collects rewards at time T4
        vm.roll(block.number + blocksPassed);
        uint256 unstakeBlockNumberUser2 = block.number;
        vm.prank(user2);
        stakingFacet.unstake(0, stakeAmount);

        // assert calculations
        LibStaking.UserInfo memory userInfo = stakingFacet.getStakingUserInfo(
            0,
            user
        );
        LibStaking.UserInfo memory userInfo2 = stakingFacet.getStakingUserInfo(
            0,
            user2
        );
        LibStaking.PoolInfo memory poolInfo = stakingFacet.getStakingPoolInfo(
            0
        );
        assertEq(userInfo.amount, 0);
        assertEq(userInfo2.amount, 0);
        assertEq(poolInfo.amount, 0);
        assertEq(stakeToken.balanceOf(user), stakeAmount);
        assertEq(stakeToken.balanceOf(user2), stakeAmount);
        assertEq(stakeToken.balanceOf(address(stakingFacet)), 0);
        // rewards
        uint256 usersCount = 2;
        uint256 expectedRewardsUser = (stakeBlockNumberUser2 -
            stakeBlockNumberUser) *
            governancePerBlock +
            ((unstakeBlockNumberUser - stakeBlockNumberUser2) *
                governancePerBlock) /
            usersCount;
        uint256 expectedRewardsUser2 = (unstakeBlockNumberUser -
            stakeBlockNumberUser2) *
            governancePerBlock +
            ((unstakeBlockNumberUser2 - unstakeBlockNumberUser) *
                governancePerBlock) /
            usersCount;
        assertApproxEqAbs(
            rewardToken.balanceOf(user),
            expectedRewardsUser,
            1e15
        );
        assertApproxEqAbs(
            rewardToken.balanceOf(user2),
            expectedRewardsUser2,
            1e15
        );
    }

    //================
    // Test helpers
    //================

    /**
     * Returns array of available pool ids
     */
    function getAvailablePoolIds() public view returns (uint256[] memory) {
        uint256 poolsLength = stakingFacet.getStakingPoolsLength();
        uint256[] memory availablePoolIds = new uint256[](poolsLength);
        for (uint256 i = 0; i < poolsLength; ++i) {
            availablePoolIds[i] = i;
        }
        return availablePoolIds;
    }
}
