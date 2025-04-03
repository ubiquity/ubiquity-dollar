// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/console2.sol";
import {DiamondTestSetup} from "../DiamondTestSetup.sol";
import {UbiquityAlgorithmicDollarManager} from "../../../src/deprecated/UbiquityAlgorithmicDollarManager.sol";
import {UbiquityGovernance} from "../../../src/deprecated/UbiquityGovernance.sol";
import {LibStaking} from "../../../src/dollar/libraries/LibStaking.sol";
import {MockERC20} from "../../../src/dollar/mocks/MockERC20.sol";

contract StakingFacetTest is DiamondTestSetup {
    UbiquityAlgorithmicDollarManager dollarManager;
    UbiquityGovernance rewardToken;
    MockERC20 stakeToken;

    address user = makeAddr("user");

    event Stake(address indexed user, uint256 indexed poolId, uint256 amount);
    event Unstake(address indexed user, uint256 indexed poolId, uint256 amount);

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
        vm.prank(admin);
        stakingFacet.createStakingPool(
            100, // allocation points
            stakeToken, 
            true // whether to update all pools
        );

        // mint 100 STK tokens to user
        stakeToken.mint(user, 100 ether);

        // user approves diamond to spend STK tokens
        vm.prank(user);
        stakeToken.approve(address(diamond), type(uint256).max);
    }

    //=====================
    // Views
    //=====================

    function testGetStakingPoolsLength_ShouldReturnNumberOfStakingPools() public {
        uint256 poolsLength = stakingFacet.getStakingPoolsLength();
        assertEq(poolsLength, 1);
    }

    //==================
    // Public methods
    //==================

    function testMassUpdateStakingPools_ShouldUpdateAllStakingPools() public {
        // before
        LibStaking.PoolInfo memory poolInfo = stakingFacet.getStakingPoolInfo(0);
        assertEq(poolInfo.lastRewardBlock, 1);

        // 10 blocks pass
        vm.roll(block.number + 10);

        stakingFacet.massUpdateStakingPools();

        // after
        poolInfo = stakingFacet.getStakingPoolInfo(0);
        assertEq(poolInfo.lastRewardBlock, 11);
    }

    function testStake_ShouldStakeTokens() public {
        // user stakes 50 STK
        vm.prank(user);
        stakingFacet.stake(0, 50 ether);

        // 10 blocks pass
        vm.roll(block.number + 10);

        // before
        LibStaking.UserInfo memory userInfo = stakingFacet.getStakingUserInfo(0, user);
        LibStaking.PoolInfo memory poolInfo = stakingFacet.getStakingPoolInfo(0);
        assertEq(poolInfo.lastRewardBlock, 1);
        assertEq(rewardToken.balanceOf(user), 0);
        assertEq(stakeToken.balanceOf(address(stakingFacet)), 50 ether);
        assertEq(userInfo.amount, 50 ether);
        assertEq(userInfo.rewardDebt, 0);
        assertEq(poolInfo.amount, 50 ether);

        vm.expectEmit(address(stakingFacet));
        emit Stake(user, 0, 50 ether);

        // user stakes 50 STK
        vm.prank(user);
        stakingFacet.stake(0, 50 ether);

        // after
        userInfo = stakingFacet.getStakingUserInfo(0, user);
        poolInfo = stakingFacet.getStakingPoolInfo(0);
        assertEq(poolInfo.lastRewardBlock, 11);
        assertEq(rewardToken.balanceOf(user), 10 ether);
        assertEq(stakeToken.balanceOf(address(stakingFacet)), 100 ether);
        assertEq(userInfo.amount, 100 ether);
        assertEq(userInfo.rewardDebt, 20 ether);
        assertEq(poolInfo.amount, 100 ether);
    }

    function testUnstake_ShouldRevert_IfUnstakeAmountIsGreaterThanUserBalance() public {
        vm.prank(user);
        vm.expectRevert("withdraw: not good");
        stakingFacet.unstake(0, 1 ether);
    }

    function testUnstake_ShouldUnstakeTokens() public {
        // user stakes 50 STK
        vm.prank(user);
        stakingFacet.stake(0, 50 ether);

        // 10 blocks pass
        vm.roll(block.number + 10);

        // before
        LibStaking.UserInfo memory userInfo = stakingFacet.getStakingUserInfo(0, user);
        LibStaking.PoolInfo memory poolInfo = stakingFacet.getStakingPoolInfo(0);
        assertEq(poolInfo.lastRewardBlock, 1);
        assertEq(rewardToken.balanceOf(user), 0);
        assertEq(userInfo.amount, 50 ether);
        assertEq(userInfo.rewardDebt, 0);
        assertEq(poolInfo.amount, 50 ether);
        assertEq(stakeToken.balanceOf(user), 50 ether);

        vm.expectEmit(address(stakingFacet));
        emit Unstake(user, 0, 25 ether);

        // user unstakes 25 STK
        vm.prank(user);
        stakingFacet.unstake(0, 25 ether);

        // after
        userInfo = stakingFacet.getStakingUserInfo(0, user);
        poolInfo = stakingFacet.getStakingPoolInfo(0);
        assertEq(poolInfo.lastRewardBlock, 11);
        assertEq(rewardToken.balanceOf(user), 10 ether);
        assertEq(userInfo.amount, 25 ether);
        assertEq(userInfo.rewardDebt, 5 ether);
        assertEq(poolInfo.amount, 25 ether);
        assertEq(stakeToken.balanceOf(user), 75 ether);
    }

    function testUpdateStakingPool_ShouldDoNothing_IfPoolHasAlreadyBeenUpdatedInTheCurrentBlock() public {
        // before
        LibStaking.PoolInfo memory poolInfo = stakingFacet.getStakingPoolInfo(0);
        assertEq(poolInfo.lastRewardBlock, 1);

        stakingFacet.updateStakingPool(0);

        // after
        poolInfo = stakingFacet.getStakingPoolInfo(0);
        assertEq(poolInfo.lastRewardBlock, 1);
    }

    function testUpdateStakingPool_ShouldUpdateLastRewardBlockNumber_IfTotalStakingTokenSupplyIsZero() public {
        // before
        LibStaking.PoolInfo memory poolInfo = stakingFacet.getStakingPoolInfo(0);
        assertEq(poolInfo.lastRewardBlock, 1);
        assertEq(poolInfo.accumulatedGovernancePerShare, 0);

        // 10 blocks pass
        vm.roll(block.number + 10);

        stakingFacet.updateStakingPool(0);

        // after
        poolInfo = stakingFacet.getStakingPoolInfo(0);
        assertEq(poolInfo.lastRewardBlock, 11);
        assertEq(poolInfo.accumulatedGovernancePerShare, 0);
    }

    // NOTICE: `admin` EOA is set to be a treasury address
    function testUpdateStakingPool_ShouldUpdateStakingPoolWithFreshValues() public {
        // user stakes 50 STK
        vm.prank(user);
        stakingFacet.stake(0, 50 ether);

        // 10 blocks pass
        vm.roll(block.number + 10);

        // before
        LibStaking.PoolInfo memory poolInfo = stakingFacet.getStakingPoolInfo(0);
        (,,,,,uint256 rewardAmount,,) = stakingFacet.getStakingSettings();
        assertEq(rewardToken.balanceOf(admin), 0);
        assertEq(rewardToken.balanceOf(address(stakingFacet)), 0);
        assertEq(poolInfo.accumulatedGovernancePerShare, 0);
        assertEq(poolInfo.lastRewardBlock, 1);
        assertEq(rewardAmount, 0);

        stakingFacet.updateStakingPool(0);

        // after
        poolInfo = stakingFacet.getStakingPoolInfo(0);
        (,,,,,rewardAmount,,) = stakingFacet.getStakingSettings();
        assertEq(rewardToken.balanceOf(admin), 2 ether);
        assertEq(rewardToken.balanceOf(address(stakingFacet)), 10 ether);
        assertEq(poolInfo.accumulatedGovernancePerShare, 0.0000002 ether);
        assertEq(poolInfo.lastRewardBlock, 11);
        assertEq(rewardAmount, 10 ether);
    }

    //======================
    // Restricted methods
    //======================

    function testSetGovernanceBonusEndBlock_ShouldUpdateBonusEndBlock() public {
        (, uint256 oldBonusEndBlock,,,,,,) = stakingFacet.getStakingSettings();
        assertEq(oldBonusEndBlock, 0);

        vm.prank(admin);
        stakingFacet.setGovernanceBonusEndBlock(1);

        (, uint256 newBonusEndBlock,,,,,,) = stakingFacet.getStakingSettings();
        assertEq(newBonusEndBlock, 1);
    }
}
