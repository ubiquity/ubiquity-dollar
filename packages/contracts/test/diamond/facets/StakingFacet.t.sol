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

    function testGetPendingStakingRewards_ShouldReturnZero_IfPoolIsEmpty()
        public
    {
        uint256 pendingRewards = stakingFacet.getPendingStakingRewards(0, user);
        assertEq(pendingRewards, 0);
    }

    function testGetPendingStakingRewards_ShouldReturnPendingRewards() public {
        // user stakes 50 STK
        vm.prank(user);
        stakingFacet.stake(0, 50 ether);

        // 10 blocks pass
        vm.roll(block.number + 10);

        uint256 pendingRewards = stakingFacet.getPendingStakingRewards(0, user);
        assertEq(pendingRewards, 10 ether);
    }

    function testGetStakingMultiplier_ShouldReturnMultiplierWithBonus() public {
        vm.startPrank(admin);
        stakingFacet.setGovernanceBonusMultiplier(10);
        stakingFacet.setGovernanceBonusEndBlock(11);
        vm.stopPrank();

        uint256 multiplier = stakingFacet.getStakingMultiplier(1, 11);
        assertEq(multiplier, 100);
    }

    function testGetStakingMultiplier_ShouldReturnMultiplierWithoutBonus()
        public
    {
        uint256 multiplier = stakingFacet.getStakingMultiplier(1, 11);
        assertEq(multiplier, 10);
    }

    function testGetStakingMultiplier_ShouldReturnMultiplierWithBonusInTheMiddleOfBonusPeriod()
        public
    {
        vm.startPrank(admin);
        stakingFacet.setGovernanceBonusMultiplier(10);
        stakingFacet.setGovernanceBonusEndBlock(11);
        vm.stopPrank();

        uint256 multiplier = stakingFacet.getStakingMultiplier(1, 21);
        assertEq(multiplier, 110);
    }

    function testGetStakingSettings_ShouldReturnStakingSettings() public {
        // user stakes 50 STK
        vm.prank(user);
        stakingFacet.stake(0, 50 ether);

        // 10 blocks pass
        vm.roll(block.number + 10);

        // refresh pool
        stakingFacet.updateStakingPool(0);

        vm.startPrank(admin);
        stakingFacet.setGovernanceBonusEndBlock(100);
        stakingFacet.setGovernanceBonusMultiplier(2);
        stakingFacet.setGovernancePerBlock(3);
        stakingFacet.setGovernanceTreasuryDivider(4);
        stakingFacet.setStakingStartBlock(20);
        vm.stopPrank();

        (
            address rewardTokenAddress,
            uint256 bonusEndBlock,
            uint256 governanceBonusMultiplier,
            uint256 governancePerBlock,
            uint256 governanceTreasuryDivider,
            uint256 rewardAmount,
            uint256 totalAllocationPoints,
            uint256 startBlock
        ) = stakingFacet.getStakingSettings();

        assertEq(rewardTokenAddress, address(rewardToken));
        assertEq(bonusEndBlock, 100);
        assertEq(governanceBonusMultiplier, 2);
        assertEq(governancePerBlock, 3);
        assertEq(governanceTreasuryDivider, 4);
        assertEq(rewardAmount, 10 ether);
        assertEq(totalAllocationPoints, 100);
        assertEq(startBlock, 20);
    }

    function testGetStakingUserInfo_ShouldReturnStakingUserInfo() public {
        // user stakes 50 STK
        vm.prank(user);
        stakingFacet.stake(0, 50 ether);

        // 10 blocks pass
        vm.roll(block.number + 10);

        // user stakes 50 STK
        vm.prank(user);
        stakingFacet.stake(0, 50 ether);

        LibStaking.UserInfo memory userInfo = stakingFacet.getStakingUserInfo(
            0,
            user
        );
        assertEq(userInfo.amount, 100 ether);
        assertEq(userInfo.rewardDebt, 20 ether);
    }

    function testGetStakingPoolInfo_ShouldReturnStakingPoolInfo() public {
        // user stakes 50 STK
        vm.prank(user);
        stakingFacet.stake(0, 50 ether);

        // 10 blocks pass
        vm.roll(block.number + 10);

        // refresh pool
        stakingFacet.updateStakingPool(0);

        LibStaking.PoolInfo memory poolInfo = stakingFacet.getStakingPoolInfo(
            0
        );
        assertEq(address(poolInfo.lpToken), address(stakeToken));
        assertEq(poolInfo.amount, 50 ether);
        assertEq(poolInfo.allocationPoints, 100);
        assertEq(poolInfo.lastRewardBlock, 11);
        assertEq(poolInfo.accumulatedGovernancePerShare, 0.0000002 ether);
    }

    function testGetStakingPoolsLength_ShouldReturnNumberOfStakingPools()
        public
    {
        uint256 poolsLength = stakingFacet.getStakingPoolsLength();
        assertEq(poolsLength, 1);
    }

    //==================
    // Public methods
    //==================

    function testMassUpdateStakingPools_ShouldUpdateAllStakingPools() public {
        // before
        LibStaking.PoolInfo memory poolInfo = stakingFacet.getStakingPoolInfo(
            0
        );
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
        LibStaking.UserInfo memory userInfo = stakingFacet.getStakingUserInfo(
            0,
            user
        );
        LibStaking.PoolInfo memory poolInfo = stakingFacet.getStakingPoolInfo(
            0
        );
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

    function testUnstake_ShouldRevert_IfUnstakeAmountIsGreaterThanUserBalance()
        public
    {
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
        LibStaking.UserInfo memory userInfo = stakingFacet.getStakingUserInfo(
            0,
            user
        );
        LibStaking.PoolInfo memory poolInfo = stakingFacet.getStakingPoolInfo(
            0
        );
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

    function testUpdateStakingPool_ShouldDoNothing_IfPoolHasAlreadyBeenUpdatedInTheCurrentBlock()
        public
    {
        // before
        LibStaking.PoolInfo memory poolInfo = stakingFacet.getStakingPoolInfo(
            0
        );
        assertEq(poolInfo.lastRewardBlock, 1);

        stakingFacet.updateStakingPool(0);

        // after
        poolInfo = stakingFacet.getStakingPoolInfo(0);
        assertEq(poolInfo.lastRewardBlock, 1);
    }

    function testUpdateStakingPool_ShouldUpdateLastRewardBlockNumber_IfTotalStakingTokenSupplyIsZero()
        public
    {
        // before
        LibStaking.PoolInfo memory poolInfo = stakingFacet.getStakingPoolInfo(
            0
        );
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
    function testUpdateStakingPool_ShouldUpdateStakingPoolWithFreshValues()
        public
    {
        // user stakes 50 STK
        vm.prank(user);
        stakingFacet.stake(0, 50 ether);

        // 10 blocks pass
        vm.roll(block.number + 10);

        // before
        LibStaking.PoolInfo memory poolInfo = stakingFacet.getStakingPoolInfo(
            0
        );
        (, , , , , uint256 rewardAmount, , ) = stakingFacet
            .getStakingSettings();
        assertEq(rewardToken.balanceOf(admin), 0);
        assertEq(rewardToken.balanceOf(address(stakingFacet)), 0);
        assertEq(poolInfo.accumulatedGovernancePerShare, 0);
        assertEq(poolInfo.lastRewardBlock, 1);
        assertEq(rewardAmount, 0);

        stakingFacet.updateStakingPool(0);

        // after
        poolInfo = stakingFacet.getStakingPoolInfo(0);
        (, , , , , rewardAmount, , ) = stakingFacet.getStakingSettings();
        assertEq(rewardToken.balanceOf(admin), 2 ether);
        assertEq(rewardToken.balanceOf(address(stakingFacet)), 10 ether);
        assertEq(poolInfo.accumulatedGovernancePerShare, 0.0000002 ether);
        assertEq(poolInfo.lastRewardBlock, 11);
        assertEq(rewardAmount, 10 ether);
    }

    //======================
    // Restricted methods
    //======================

    function testCreateStakingPool_ShouldRevert_IfLpTokenAddressIsZero()
        public
    {
        vm.prank(admin);
        vm.expectRevert("Zero address detected");
        stakingFacet.createStakingPool(
            100, // allocation points
            MockERC20(address(0)),
            true // whether to update all pools
        );
    }

    function testCreateStakingPool_ShouldCreateStakingPoolWithoutMassUpdate()
        public
    {
        LibStaking.PoolInfo memory poolInfo = stakingFacet.getStakingPoolInfo(
            0
        );
        (, , , , , , uint256 totalAllocationPoints, ) = stakingFacet
            .getStakingSettings();

        assertEq(totalAllocationPoints, 100);
        assertEq(address(poolInfo.lpToken), address(stakeToken));
        assertEq(poolInfo.amount, 0);
        assertEq(poolInfo.allocationPoints, 100);
        assertEq(poolInfo.lastRewardBlock, block.number);
        assertEq(poolInfo.accumulatedGovernancePerShare, 0);
    }

    function testCreateStakingPool_ShouldCreateStakingPoolWithMassUpdate()
        public
    {
        // 10 blocks pass
        vm.roll(block.number + 10);

        // admin increases `startBlock` number
        vm.prank(admin);
        stakingFacet.setStakingStartBlock(block.number + 100);

        // before
        LibStaking.PoolInfo memory poolInfo1 = stakingFacet.getStakingPoolInfo(
            0
        );
        assertEq(poolInfo1.lastRewardBlock, 1);

        // admin creates 2nd pool
        vm.prank(admin);
        stakingFacet.createStakingPool(
            100, // allocation points
            stakeToken,
            true // whether to update all pools
        );

        // after
        poolInfo1 = stakingFacet.getStakingPoolInfo(0);
        LibStaking.PoolInfo memory poolInfo2 = stakingFacet.getStakingPoolInfo(
            1
        );
        assertEq(poolInfo1.lastRewardBlock, 11);
        assertEq(poolInfo2.lastRewardBlock, 111);
    }

    function testSetGovernanceBonusEndBlock_ShouldRevert_IfBonusEndBlockIsInThePast()
        public
    {
        vm.prank(admin);
        vm.expectRevert("Bonus end block can't be in the past");
        stakingFacet.setGovernanceBonusEndBlock(0);
    }

    function testSetGovernanceBonusEndBlock_ShouldUpdateBonusEndBlock() public {
        (, uint256 oldBonusEndBlock, , , , , , ) = stakingFacet
            .getStakingSettings();
        assertEq(oldBonusEndBlock, 0);

        vm.prank(admin);
        stakingFacet.setGovernanceBonusEndBlock(1);

        (, uint256 newBonusEndBlock, , , , , , ) = stakingFacet
            .getStakingSettings();
        assertEq(newBonusEndBlock, 1);
    }

    function testSetGovernanceBonusMultiplier_ShouldUpdateGovernanceBonusMultiplier()
        public
    {
        (, , uint256 oldGovernanceBonusMultiplier, , , , , ) = stakingFacet
            .getStakingSettings();
        assertEq(oldGovernanceBonusMultiplier, 0);

        vm.prank(admin);
        stakingFacet.setGovernanceBonusMultiplier(10);

        (, , uint256 newGovernanceBonusMultiplier, , , , , ) = stakingFacet
            .getStakingSettings();
        assertEq(newGovernanceBonusMultiplier, 10);
    }

    function testSetGovernancePerBlock_ShouldRevert_IfRewardsAreEmpty() public {
        vm.prank(admin);
        vm.expectRevert("Empty rewards");
        stakingFacet.setGovernancePerBlock(0);
    }

    function testSetGovernancePerBlock_ShouldUpdateGovernancePerBlock() public {
        (, , , uint256 oldGovernancePerBlock, , , , ) = stakingFacet
            .getStakingSettings();
        assertEq(oldGovernancePerBlock, 1 ether);

        vm.prank(admin);
        stakingFacet.setGovernancePerBlock(2 ether);

        (, , , uint256 newGovernancePerBlock, , , , ) = stakingFacet
            .getStakingSettings();
        assertEq(newGovernancePerBlock, 2 ether);
    }

    function testSetGovernanceTreasuryDivider_ShouldRevert_IfNewGovernanceTreasuryDividerIsZero()
        public
    {
        vm.prank(admin);
        vm.expectRevert("Treasury divider can't be zero");
        stakingFacet.setGovernanceTreasuryDivider(0);
    }

    function testSetGovernanceTreasuryDivider_ShouldUpdateGovernanceTreasuryDivider()
        public
    {
        (, , , , uint256 oldGovernanceTreasuryDivider, , , ) = stakingFacet
            .getStakingSettings();
        assertEq(oldGovernanceTreasuryDivider, 5);

        vm.prank(admin);
        stakingFacet.setGovernanceTreasuryDivider(10);

        (, , , , uint256 newGovernanceTreasuryDivider, , , ) = stakingFacet
            .getStakingSettings();
        assertEq(newGovernanceTreasuryDivider, 10);
    }

    function testSetStakingRewardToken_ShouldRevert_IfStakingRewardTokenIsZeroAddress()
        public
    {
        vm.prank(admin);
        vm.expectRevert("Zero address detected");
        stakingFacet.setStakingRewardToken(address(0));
    }

    function testSetStakingRewardToken_ShouldUpdateStakingRewardToken() public {
        (address oldRewardToken, , , , , , , ) = stakingFacet
            .getStakingSettings();
        assertEq(oldRewardToken, address(rewardToken));

        vm.prank(admin);
        stakingFacet.setStakingRewardToken(address(1));

        (address newRewardToken, , , , , , , ) = stakingFacet
            .getStakingSettings();
        assertEq(newRewardToken, address(1));
    }

    function testSetStakingStartBlock_ShouldRevert_IfStartBlockIsInThePast()
        public
    {
        vm.prank(admin);
        vm.expectRevert("Can't start in the past");
        stakingFacet.setStakingStartBlock(0);
    }

    function testSetStakingStartBlock_ShouldUpdateStakingStartBlock() public {
        (, , , , , , , uint256 oldStartBlock) = stakingFacet
            .getStakingSettings();
        assertEq(oldStartBlock, block.number);

        vm.prank(admin);
        stakingFacet.setStakingStartBlock(block.number + 1);

        (, , , , , , , uint256 newStartBlock) = stakingFacet
            .getStakingSettings();
        assertEq(newStartBlock, block.number + 1);
    }

    function testUpdateStakingPool_ShouldRevert_IfPoolDoesNotExist() public {
        vm.prank(admin);
        vm.expectRevert("Pool does not exist");
        stakingFacet.updateStakingPool(1, 0, true);
    }

    function testUpdateStakingPool_ShouldUpdateStakingPoolSettings() public {
        LibStaking.PoolInfo memory poolInfo = stakingFacet.getStakingPoolInfo(
            0
        );
        (, , , , , , uint256 oldTotalAllocationPoints, ) = stakingFacet
            .getStakingSettings();
        assertEq(poolInfo.lastRewardBlock, 1);
        assertEq(oldTotalAllocationPoints, 100);
        assertEq(poolInfo.allocationPoints, 100);

        // 10 blocks pass
        vm.roll(block.number + 10);

        vm.prank(admin);
        stakingFacet.updateStakingPool(0, 50, true);

        poolInfo = stakingFacet.getStakingPoolInfo(0);
        (, , , , , , uint256 newTotalAllocationPoints, ) = stakingFacet
            .getStakingSettings();
        assertEq(poolInfo.lastRewardBlock, 11);
        assertEq(newTotalAllocationPoints, 50);
        assertEq(poolInfo.allocationPoints, 50);
    }

    //======================
    // Internal helpers
    //======================

    function testSafeGovernanceTransfer_ShouldTransferRewards() public {
        // user stakes 50 STK
        vm.prank(user);
        stakingFacet.stake(0, 50 ether);

        // 10 blocks pass
        vm.roll(block.number + 10);

        // refresh staking pool
        stakingFacet.updateStakingPool(0);

        // before
        (, , , , , uint256 rewardAmount, , ) = stakingFacet
            .getStakingSettings();
        assertEq(rewardAmount, 10 ether);
        assertEq(rewardToken.balanceOf(user), 0);

        // user stakes 50 STK
        vm.prank(user);
        stakingFacet.stake(0, 50 ether);

        // after
        (, , , , , rewardAmount, , ) = stakingFacet.getStakingSettings();
        assertEq(rewardAmount, 0);
        assertEq(rewardToken.balanceOf(user), 10 ether);
    }
}
