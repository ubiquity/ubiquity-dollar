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

    function testStaking_ShouldStakeAndUnstakeTokens(
        uint256 stakeAmount,
        uint256 blocksPassed,
        uint256 governancePerBlock
    ) public {
        stakeAmount = bound(stakeAmount, 1, 100_000_000 ether);
        blocksPassed = bound(blocksPassed, 1, 2628000 * 10); // max 10 years
        governancePerBlock = bound(governancePerBlock, 1, 100_000_000 ether);

        // admin sets governance per block
        vm.prank(admin);
        stakingFacet.setGovernancePerBlock(governancePerBlock);

        // mint X STK tokens to users
        stakeToken.mint(user, stakeAmount);
        stakeToken.mint(user2, stakeAmount);

        // before staking
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
        assertEq(rewardToken.balanceOf(user), 0);
        assertEq(rewardToken.balanceOf(user2), 0);
        assertEq(stakeToken.balanceOf(address(stakingFacet)), 0);
        assertEq(userInfo.amount, 0);
        assertEq(userInfo2.amount, 0);
        assertEq(poolInfo.amount, 0);

        // users stake STK
        vm.prank(user);
        stakingFacet.stake(0, stakeAmount);
        vm.prank(user2);
        stakingFacet.stake(0, stakeAmount);

        // Y blocks pass
        vm.roll(block.number + blocksPassed);

        // users collect rewards
        vm.prank(user);
        stakingFacet.stake(0, 0);
        vm.prank(user2);
        stakingFacet.stake(0, 0);

        // after staking
        uint256 usersCount = 2;
        userInfo = stakingFacet.getStakingUserInfo(0, user);
        userInfo2 = stakingFacet.getStakingUserInfo(0, user2);
        poolInfo = stakingFacet.getStakingPoolInfo(0);
        assertApproxEqAbs(
            rewardToken.balanceOf(user),
            (blocksPassed * governancePerBlock) / usersCount,
            1e14
        );
        assertApproxEqAbs(
            rewardToken.balanceOf(user2),
            (blocksPassed * governancePerBlock) / usersCount,
            1e14
        );
        assertEq(
            stakeToken.balanceOf(address(stakingFacet)),
            stakeAmount * usersCount
        );
        assertEq(userInfo.amount, stakeAmount);
        assertEq(userInfo2.amount, stakeAmount);
        assertEq(poolInfo.amount, stakeAmount * usersCount);

        // users unstake STK
        vm.prank(user);
        stakingFacet.unstake(0, stakeAmount);
        vm.prank(user2);
        stakingFacet.unstake(0, stakeAmount);

        userInfo = stakingFacet.getStakingUserInfo(0, user);
        userInfo2 = stakingFacet.getStakingUserInfo(0, user2);
        poolInfo = stakingFacet.getStakingPoolInfo(0);
        assertEq(userInfo.amount, 0);
        assertEq(userInfo2.amount, 0);
        assertEq(poolInfo.amount, 0);
        assertEq(stakeToken.balanceOf(user), stakeAmount);
        assertEq(stakeToken.balanceOf(user2), stakeAmount);
        assertEq(stakeToken.balanceOf(address(stakingFacet)), 0);
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
