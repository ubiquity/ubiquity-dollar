// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/console.sol";
import {DiamondTestSetup} from "../DiamondTestSetup.sol";
import {UbiquityAlgorithmicDollarManager} from "../../../src/deprecated/UbiquityAlgorithmicDollarManager.sol";
import {UbiquityGovernance} from "../../../src/deprecated/UbiquityGovernance.sol";
import {LibStaking} from "../../../src/dollar/libraries/LibStaking.sol";
import {MockERC20} from "../../../src/dollar/mocks/MockERC20.sol";

contract StakingFacetTest is DiamondTestSetup {
    UbiquityAlgorithmicDollarManager dollarManager;
    UbiquityGovernance rewardToken;
    MockERC20 stakeToken;

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

        // admin creates a new staking pool
        vm.prank(admin);
        stakingFacet.createStakingPool(
            100, // allocation points
            stakeToken, 
            true // whether to update all pools
        );
    }

    //=====================
    // Views
    //=====================

    function testGetStakingPoolsLength_ShouldReturnNumberOfStakingPools() public {
        uint256 poolsLength = stakingFacet.getStakingPoolsLength();
        assertEq(poolsLength, 1);
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
