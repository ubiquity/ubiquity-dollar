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

    event GovernanceBonusEndBlockSet(
        uint256 indexed newGovernanceBonusEndBlock
    );
    event GovernanceBonusMultiplierSet(
        uint256 indexed newGovernanceBonusMultiplier
    );
    event GovernancePerBlockSet(uint256 indexed newGovernancePerBlock);
    event GovernanceTreasuryDividerSet(
        uint256 indexed newGovernanceTreasuryDivider
    );
    event Stake(address indexed user, uint256 indexed poolId, uint256 amount);
    event StakingPoolCreated(
        uint256 indexed allocationPoints,
        address indexed lpToken
    );
    event StakingPoolUpdated(uint256 indexed poolId);
    event StakingPoolAllocationUpdated(
        uint256 indexed poolId,
        uint256 indexed allocationPoints
    );
    event StakingRewardTokenSet(address indexed newRewardToken);
    event StakingStartBlockSet(uint256 indexed newStartBlock);
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
        vm.startPrank(admin);
        stakingFacet.createStakingPool(
            100, // allocation points
            stakeToken
        );
        vm.stopPrank();

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
        stakingFacet.setGovernancePerBlock(0.0001 ether);
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
        assertEq(governancePerBlock, 0.0001 ether);
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
        // admin creates 2nd pool
        vm.startPrank(admin);
        stakingFacet.createStakingPool(
            100, // allocation points
            stakeToken
        );
        vm.stopPrank();

        // before
        LibStaking.PoolInfo memory poolInfo = stakingFacet.getStakingPoolInfo(
            0
        );
        LibStaking.PoolInfo memory poolInfo2 = stakingFacet.getStakingPoolInfo(
            1
        );
        assertEq(poolInfo.lastRewardBlock, 1);
        assertEq(poolInfo2.lastRewardBlock, 1);

        // 10 blocks pass
        vm.roll(block.number + 10);

        stakingFacet.massUpdateStakingPools();

        // after
        poolInfo = stakingFacet.getStakingPoolInfo(0);
        poolInfo2 = stakingFacet.getStakingPoolInfo(1);
        assertEq(poolInfo.lastRewardBlock, 11);
        assertEq(poolInfo2.lastRewardBlock, 11);
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

    /**
     * Scenario:
     *
     * Step 1, admin creates 3 staking pools
     * - Pool 1: 100 allocation points
     * - Pool 2: 300 allocation points
     * - Pool 3: 0 allocation points
     *
     * Step 2
     * - user stakes 50 STK in `Pool 1`
     * - user2 stakes 50 STK in `Pool 2`
     * - user3 stakes 50 STK in `Pool 3`
     *
     * Step 3, 10 blocks pass
     *
     * Step 4, users unstake half of the tokens
     *
     * Step 5, assert that:
     * - user gets 2.5 reward tokens (25% pool allocation)
     * - user2 gets 7.5 reward tokens (75% pool allocation)
     * - user3 gets 0 reward tokens (0% pool allocation)
     */
    function testUnstake_ShouldUnstakeTokens_WhenMultipleUsersUnstakeFromMultiplePools()
        public
    {
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");

        // admin creates 2 more staking pool
        vm.startPrank(admin);
        stakingFacet.createStakingPool(
            300, // allocation points
            stakeToken
        );
        stakingFacet.createStakingPool(
            0, // allocation points
            stakeToken
        );
        vm.stopPrank();

        // mint STK tokens to users
        stakeToken.mint(user2, 100 ether);
        stakeToken.mint(user3, 100 ether);

        // users approve diamond to spend STK tokens
        vm.prank(user2);
        stakeToken.approve(address(diamond), type(uint256).max);
        vm.prank(user3);
        stakeToken.approve(address(diamond), type(uint256).max);

        // users stake tokens in different pools
        vm.prank(user);
        stakingFacet.stake(0, 50 ether);
        vm.prank(user2);
        stakingFacet.stake(1, 50 ether);
        vm.prank(user3);
        stakingFacet.stake(2, 50 ether);

        // 10 blocks pass
        vm.roll(block.number + 10);

        // before (user)
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

        // before (user2)
        LibStaking.UserInfo memory userInfo2 = stakingFacet.getStakingUserInfo(
            1,
            user2
        );
        LibStaking.PoolInfo memory poolInfo2 = stakingFacet.getStakingPoolInfo(
            1
        );
        assertEq(poolInfo2.lastRewardBlock, 1);
        assertEq(rewardToken.balanceOf(user2), 0);
        assertEq(userInfo2.amount, 50 ether);
        assertEq(userInfo2.rewardDebt, 0);
        assertEq(poolInfo2.amount, 50 ether);
        assertEq(stakeToken.balanceOf(user2), 50 ether);

        // before (user3)
        LibStaking.UserInfo memory userInfo3 = stakingFacet.getStakingUserInfo(
            2,
            user3
        );
        LibStaking.PoolInfo memory poolInfo3 = stakingFacet.getStakingPoolInfo(
            2
        );
        assertEq(poolInfo3.lastRewardBlock, 1);
        assertEq(rewardToken.balanceOf(user3), 0);
        assertEq(userInfo3.amount, 50 ether);
        assertEq(userInfo3.rewardDebt, 0);
        assertEq(poolInfo3.amount, 50 ether);
        assertEq(stakeToken.balanceOf(user3), 50 ether);

        // users unstake 25 STK each
        vm.prank(user);
        stakingFacet.unstake(0, 25 ether);
        vm.prank(user2);
        stakingFacet.unstake(1, 25 ether);
        vm.prank(user3);
        stakingFacet.unstake(2, 25 ether);

        // after (user)
        userInfo = stakingFacet.getStakingUserInfo(0, user);
        poolInfo = stakingFacet.getStakingPoolInfo(0);
        assertEq(poolInfo.lastRewardBlock, 11);
        assertEq(rewardToken.balanceOf(user), 2.5 ether);
        assertEq(userInfo.amount, 25 ether);
        assertEq(userInfo.rewardDebt, 1.25 ether);
        assertEq(poolInfo.amount, 25 ether);
        assertEq(stakeToken.balanceOf(user), 75 ether);

        // after (user2)
        userInfo2 = stakingFacet.getStakingUserInfo(1, user2);
        poolInfo2 = stakingFacet.getStakingPoolInfo(1);
        assertEq(poolInfo2.lastRewardBlock, 11);
        assertEq(rewardToken.balanceOf(user2), 7.5 ether);
        assertEq(userInfo2.amount, 25 ether);
        assertEq(userInfo2.rewardDebt, 3.75 ether);
        assertEq(poolInfo2.amount, 25 ether);
        assertEq(stakeToken.balanceOf(user2), 75 ether);

        // after (user3)
        userInfo3 = stakingFacet.getStakingUserInfo(2, user3);
        poolInfo3 = stakingFacet.getStakingPoolInfo(2);
        assertEq(poolInfo3.lastRewardBlock, 11);
        assertEq(rewardToken.balanceOf(user3), 0);
        assertEq(userInfo3.amount, 25 ether);
        assertEq(userInfo3.rewardDebt, 0);
        assertEq(poolInfo3.amount, 25 ether);
        assertEq(stakeToken.balanceOf(user3), 75 ether);
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

        vm.expectEmit(address(stakingFacet));
        emit StakingPoolUpdated(0);

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

    // NOTICE: `admin` EOA is set to be a treasury address
    function testUpdateStakingPool_ShouldNotMintRewardsToTreasury_IfGovernanceTreasuryDividerIsZero()
        public
    {
        // admin disables treasury rewards
        vm.prank(admin);
        stakingFacet.setGovernanceTreasuryDivider(0);

        // user stakes 50 STK
        vm.prank(user);
        stakingFacet.stake(0, 50 ether);

        // 10 blocks pass
        vm.roll(block.number + 10);

        // before
        assertEq(rewardToken.balanceOf(admin), 0);

        stakingFacet.updateStakingPool(0);

        // after
        assertEq(rewardToken.balanceOf(admin), 0);
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
            MockERC20(address(0))
        );
    }

    function testCreateStakingPool_ShouldRevert_IfLpTokenIsUsedAsCollateralInUbiquityPool()
        public
    {
        // create a new staking token
        MockERC20 newStakeToken = new MockERC20("STK_NEW", "STK_NEW", 18);

        // admin adds collateral token to the pool
        vm.prank(admin);
        ubiquityPoolFacet.addCollateralToken(
            address(newStakeToken),
            address(0), // collateral token price feed
            50_000e18 // max 50_000 of collateral tokens is allowed
        );

        // admin tries to add new staking token which is already used as collateral in `UbiquityPool`
        vm.prank(admin);
        vm.expectRevert("Already used as collateral");
        stakingFacet.createStakingPool(
            100, // allocation points
            newStakeToken
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

        vm.expectEmit(address(stakingFacet));
        emit StakingPoolCreated(100, address(stakeToken));

        // admin creates 2nd pool
        vm.startPrank(admin);
        stakingFacet.createStakingPool(
            100, // allocation points
            stakeToken
        );
        vm.stopPrank();

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

        vm.expectEmit(address(stakingFacet));
        emit GovernanceBonusEndBlockSet(1);

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

        vm.expectEmit(address(stakingFacet));
        emit GovernanceBonusMultiplierSet(10);

        vm.prank(admin);
        stakingFacet.setGovernanceBonusMultiplier(10);

        (, , uint256 newGovernanceBonusMultiplier, , , , , ) = stakingFacet
            .getStakingSettings();
        assertEq(newGovernanceBonusMultiplier, 10);
    }

    function testSetGovernancePerBlock_ShouldRevert_IfRewardsAreEmpty() public {
        vm.prank(admin);
        vm.expectRevert("Rewards are too small");
        stakingFacet.setGovernancePerBlock(0);
    }

    function testSetGovernancePerBlock_ShouldUpdateGovernancePerBlock() public {
        (, , , uint256 oldGovernancePerBlock, , , , ) = stakingFacet
            .getStakingSettings();
        assertEq(oldGovernancePerBlock, 1 ether);

        vm.expectEmit(address(stakingFacet));
        emit GovernancePerBlockSet(2 ether);

        vm.prank(admin);
        stakingFacet.setGovernancePerBlock(2 ether);

        (, , , uint256 newGovernancePerBlock, , , , ) = stakingFacet
            .getStakingSettings();
        assertEq(newGovernancePerBlock, 2 ether);
    }

    function testSetGovernanceTreasuryDivider_ShouldUpdateGovernanceTreasuryDivider()
        public
    {
        (, , , , uint256 oldGovernanceTreasuryDivider, , , ) = stakingFacet
            .getStakingSettings();
        assertEq(oldGovernanceTreasuryDivider, 5);

        vm.expectEmit(address(stakingFacet));
        emit GovernanceTreasuryDividerSet(10);

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

    function testSetStakingRewardToken_ShouldRevert__IfRewardTokenIsUsedAsCollateralInUbiquityPool()
        public
    {
        // create a new reward token
        MockERC20 newRewardToken = new MockERC20("RWD_NEW", "RWD_NEW", 18);

        // admin adds collateral token to the pool
        vm.prank(admin);
        ubiquityPoolFacet.addCollateralToken(
            address(newRewardToken),
            address(0), // collateral token price feed
            50_000e18 // max 50_000 of collateral tokens is allowed
        );

        // admin tries to set a new reward token which is already used as collateral in `UbiquityPool`
        vm.prank(admin);
        vm.expectRevert("Already used as collateral");
        stakingFacet.setStakingRewardToken(address(newRewardToken));
    }

    function testSetStakingRewardToken_ShouldUpdateStakingRewardToken() public {
        (address oldRewardToken, , , , , , , ) = stakingFacet
            .getStakingSettings();
        assertEq(oldRewardToken, address(rewardToken));

        vm.expectEmit(address(stakingFacet));
        emit StakingRewardTokenSet(address(1));

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

        vm.expectEmit(address(stakingFacet));
        emit StakingStartBlockSet(block.number + 1);

        vm.prank(admin);
        stakingFacet.setStakingStartBlock(block.number + 1);

        (, , , , , , , uint256 newStartBlock) = stakingFacet
            .getStakingSettings();
        assertEq(newStartBlock, block.number + 1);
    }

    function testUpdateStakingPool_ShouldRevert_IfPoolDoesNotExist() public {
        vm.prank(admin);
        vm.expectRevert("Pool does not exist");
        stakingFacet.updateStakingPool(1, 0);
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

        vm.expectEmit(address(stakingFacet));
        emit StakingPoolAllocationUpdated(0, 50);

        vm.startPrank(admin);
        stakingFacet.updateStakingPool(0, 50);
        vm.stopPrank();

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
