// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/console.sol";
import {DiamondTestSetup} from "../DiamondTestSetup.sol";
import {IDiamondCut} from "../../../src/dollar/interfaces/IDiamondCut.sol";
import {StabilityPoolFacet} from "../../../src/dollar/facets/StabilityPoolFacet.sol";
import {IStabilityPoolFacet} from "../../../src/dollar/interfaces/IStabilityPoolFacet.sol";
import {LibStabilityPool} from "../../../src/dollar/libraries/LibStabilityPool.sol";
import {MockStabilityPool} from "../../../src/dollar/mocks/MockStabilityPool.sol";
import {MockERC20} from "../../../src/dollar/mocks/MockERC20.sol";
import {IDiamondCut as IDiamondCutFacet} from "../../../src/dollar/interfaces/IDiamondCut.sol";

contract StabilityPoolFacetTest is DiamondTestSetup {
    StabilityPoolFacet stabilityPoolFacet;
    StabilityPoolFacet stabilityPoolFacetImplementation;
    MockStabilityPool mockStabilityPool;
    MockERC20 lusdToken;
    MockERC20 lqtyToken;

    address treasury = address(0x999);

    // Events
    event DepositedToPool(address indexed sender, uint256 amount);
    event WithdrawnFromPool(address indexed sender, uint256 amount);
    event RewardsHarvested(
        address indexed sender,
        uint256 ethReward,
        uint256 lqtyReward
    );
    event StabilityPoolAddressSet(address indexed stabilityPool);
    event RewardThresholdSet(uint256 threshold);
    event SpTreasuryAddressSet(address indexed treasury);

    function setUp() public override {
        super.setUp();

        // Deploy mock tokens
        lusdToken = new MockERC20("LUSD", "LUSD", 18);
        lqtyToken = new MockERC20("LQTY", "LQTY", 18);

        // Deploy mock stability pool
        mockStabilityPool = new MockStabilityPool(
            address(lusdToken),
            address(lqtyToken)
        );

        // Deploy facet implementation
        stabilityPoolFacetImplementation = new StabilityPoolFacet();

        // Add facet to diamond via diamondCut
        bytes4[] memory selectors = getSelectorsFromAbi(
            "/out/StabilityPoolFacet.sol/StabilityPoolFacet.json"
        );

        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(stabilityPoolFacetImplementation),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });

        vm.prank(owner);
        IDiamondCutFacet(address(diamond)).diamondCut(
            cuts,
            address(0),
            ""
        );

        // Initialize facet reference
        stabilityPoolFacet = StabilityPoolFacet(address(diamond));

        // Configure the facet
        vm.startPrank(admin);
        stabilityPoolFacet.setStabilityPoolAddress(
            address(mockStabilityPool)
        );
        stabilityPoolFacet.setSpTreasuryAddress(treasury);
        stabilityPoolFacet.setRewardThreshold(0.01 ether); // 0.01 ETH threshold
        vm.stopPrank();
    }

    // ==================
    // View Tests
    // ==================

    function test_StabilityPoolAddress() public {
        assertEq(
            stabilityPoolFacet.stabilityPoolAddress(),
            address(mockStabilityPool)
        );
    }

    function test_SpTreasuryAddress() public {
        assertEq(stabilityPoolFacet.spTreasuryAddress(), treasury);
    }

    function test_RewardThreshold() public {
        assertEq(stabilityPoolFacet.rewardThreshold(), 0.01 ether);
    }

    function test_InitialTotalPrincipal() public {
        assertEq(stabilityPoolFacet.totalPrincipalInPool(), 0);
    }

    // ==================
    // Deposit Tests
    // ==================

    function test_DepositToPool() public {
        uint256 amount = 1000e18;

        // Mint LUSD to user and approve
        lusdToken.mint(user1, amount);
        vm.prank(user1);
        lusdToken.approve(address(diamond), amount);

        // Deposit
        vm.prank(user1);
        stabilityPoolFacet.depositToPool(amount);

        assertEq(stabilityPoolFacet.totalPrincipalInPool(), amount);
        assertEq(lusdToken.balanceOf(user1), 0);
        assertEq(lusdToken.balanceOf(address(mockStabilityPool)), amount);
    }

    function test_DepositToPool_EmitsEvent() public {
        uint256 amount = 1000e18;
        lusdToken.mint(user1, amount);
        vm.prank(user1);
        lusdToken.approve(address(diamond), amount);

        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit DepositedToPool(user1, amount);
        stabilityPoolFacet.depositToPool(amount);
    }

    function test_DepositToPool_RevertZeroAmount() public {
        vm.prank(user1);
        vm.expectRevert("StabilityPool: zero amount");
        stabilityPoolFacet.depositToPool(0);
    }

    function test_DepositToPool_RevertInsufficientBalance() public {
        uint256 amount = 1000e18;
        vm.prank(user1);
        lusdToken.approve(address(diamond), amount);

        vm.prank(user1);
        vm.expectRevert();
        stabilityPoolFacet.depositToPool(amount);
    }

    // ==================
    // Withdraw Tests
    // ==================

    function test_WithdrawFromPool() public {
        uint256 amount = 1000e18;

        // Setup: deposit first
        lusdToken.mint(user1, amount);
        vm.prank(user1);
        lusdToken.approve(address(diamond), amount);
        vm.prank(user1);
        stabilityPoolFacet.depositToPool(amount);

        // Withdraw
        vm.prank(user1);
        stabilityPoolFacet.withdrawFromPool(amount);

        assertEq(stabilityPoolFacet.totalPrincipalInPool(), 0);
        assertEq(lusdToken.balanceOf(user1), amount);
    }

    function test_WithdrawFromPool_EmitsEvent() public {
        uint256 amount = 1000e18;

        lusdToken.mint(user1, amount);
        vm.prank(user1);
        lusdToken.approve(address(diamond), amount);
        vm.prank(user1);
        stabilityPoolFacet.depositToPool(amount);

        vm.prank(user1);
        vm.expectEmit(true, false, false, true);
        emit WithdrawnFromPool(user1, amount);
        stabilityPoolFacet.withdrawFromPool(amount);
    }

    function test_WithdrawFromPool_RevertZeroAmount() public {
        vm.prank(user1);
        vm.expectRevert("StabilityPool: zero amount");
        stabilityPoolFacet.withdrawFromPool(0);
    }

    function test_WithdrawFromPool_RevertExceedsPrincipal() public {
        uint256 depositAmount = 500e18;
        uint256 withdrawAmount = 1000e18;

        lusdToken.mint(user1, depositAmount);
        vm.prank(user1);
        lusdToken.approve(address(diamond), depositAmount);
        vm.prank(user1);
        stabilityPoolFacet.depositToPool(depositAmount);

        vm.prank(user1);
        vm.expectRevert("StabilityPool: exceeds principal");
        stabilityPoolFacet.withdrawFromPool(withdrawAmount);
    }

    function test_WithdrawFromPool_Partial() public {
        uint256 depositAmount = 1000e18;
        uint256 withdrawAmount = 400e18;

        lusdToken.mint(user1, depositAmount);
        vm.prank(user1);
        lusdToken.approve(address(diamond), depositAmount);
        vm.prank(user1);
        stabilityPoolFacet.depositToPool(depositAmount);

        vm.prank(user1);
        stabilityPoolFacet.withdrawFromPool(withdrawAmount);

        assertEq(
            stabilityPoolFacet.totalPrincipalInPool(),
            depositAmount - withdrawAmount
        );
        assertEq(lusdToken.balanceOf(user1), withdrawAmount);
    }

    // ==================
    // Harvest Tests
    // ==================

    function test_HarvestRewards_NoRewards() public {
        // Should not revert when there are no rewards
        stabilityPoolFacet.harvestRewards();
    }

    function test_HarvestRewards_ETHReward() public {
        uint256 ethReward = 0.5 ether;

        // Fund the mock with ETH
        vm.deal(address(mockStabilityPool), ethReward);
        mockStabilityPool.setETHGain(address(diamond), ethReward);

        uint256 treasuryBalBefore = treasury.balance;

        stabilityPoolFacet.harvestRewards();

        // ETH reward should be sent to treasury
        assertEq(treasury.balance - treasuryBalBefore, ethReward);
    }

    function test_HarvestRewards_LQTYReward() public {
        uint256 lqtyReward = 100e18;

        // Mint LQTY to the mock stability pool
        lqtyToken.mint(address(mockStabilityPool), lqtyReward);
        mockStabilityPool.setLQTYGain(address(diamond), lqtyReward);

        uint256 treasuryBalBefore = lqtyToken.balanceOf(treasury);

        stabilityPoolFacet.harvestRewards();

        assertEq(lqtyToken.balanceOf(treasury) - treasuryBalBefore, lqtyReward);
    }

    function test_HarvestRewards_BothRewards() public {
        uint256 ethReward = 0.5 ether;
        uint256 lqtyReward = 100e18;

        vm.deal(address(mockStabilityPool), ethReward);
        mockStabilityPool.setETHGain(address(diamond), ethReward);

        lqtyToken.mint(address(mockStabilityPool), lqtyReward);
        mockStabilityPool.setLQTYGain(address(diamond), lqtyReward);

        uint256 treasuryETHBefore = treasury.balance;
        uint256 treasuryLQTYBefore = lqtyToken.balanceOf(treasury);

        stabilityPoolFacet.harvestRewards();

        assertEq(treasury.balance - treasuryETHBefore, ethReward);
        assertEq(
            lqtyToken.balanceOf(treasury) - treasuryLQTYBefore,
            lqtyReward
        );
    }

    function test_HarvestRewards_EmitsEvent() public {
        uint256 ethReward = 0.5 ether;
        uint256 lqtyReward = 100e18;

        vm.deal(address(mockStabilityPool), ethReward);
        mockStabilityPool.setETHGain(address(diamond), ethReward);

        lqtyToken.mint(address(mockStabilityPool), lqtyReward);
        mockStabilityPool.setLQTYGain(address(diamond), lqtyReward);

        vm.expectEmit(true, false, false, true);
        emit RewardsHarvested(address(this), ethReward, lqtyReward);
        stabilityPoolFacet.harvestRewards();
    }

    // ==================
    // Auto-Harvest on Withdraw
    // ==================

    function test_WithdrawTriggersAutoHarvest() public {
        uint256 depositAmount = 1000e18;
        uint256 ethReward = 0.5 ether;

        // Setup deposit
        lusdToken.mint(user1, depositAmount);
        vm.prank(user1);
        lusdToken.approve(address(diamond), depositAmount);
        vm.prank(user1);
        stabilityPoolFacet.depositToPool(depositAmount);

        // Simulate ETH reward above threshold
        vm.deal(address(mockStabilityPool), ethReward);
        mockStabilityPool.setETHGain(address(diamond), ethReward);

        uint256 treasuryETHBefore = treasury.balance;

        // Withdraw should auto-harvest
        vm.prank(user1);
        stabilityPoolFacet.withdrawFromPool(depositAmount);

        // ETH should have been harvested to treasury
        assertEq(treasury.balance - treasuryETHBefore, ethReward);
    }

    // ==================
    // Admin Functions
    // ==================

    function test_SetStabilityPoolAddress() public {
        MockStabilityPool newPool = new MockStabilityPool(
            address(lusdToken),
            address(lqtyToken)
        );

        vm.prank(admin);
        stabilityPoolFacet.setStabilityPoolAddress(address(newPool));

        assertEq(
            stabilityPoolFacet.stabilityPoolAddress(),
            address(newPool)
        );
    }

    function test_SetStabilityPoolAddress_EmitsEvent() public {
        MockStabilityPool newPool = new MockStabilityPool(
            address(lusdToken),
            address(lqtyToken)
        );

        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit StabilityPoolAddressSet(address(newPool));
        stabilityPoolFacet.setStabilityPoolAddress(address(newPool));
    }

    function test_SetStabilityPoolAddress_RevertZeroAddress() public {
        vm.prank(admin);
        vm.expectRevert("StabilityPool: zero address");
        stabilityPoolFacet.setStabilityPoolAddress(address(0));
    }

    function test_SetStabilityPoolAddress_RevertNotAdmin() public {
        vm.prank(user1);
        vm.expectRevert("Manager: Caller is not admin");
        stabilityPoolFacet.setStabilityPoolAddress(address(mockStabilityPool));
    }

    function test_SetRewardThreshold() public {
        uint256 newThreshold = 0.05 ether;
        vm.prank(admin);
        stabilityPoolFacet.setRewardThreshold(newThreshold);

        assertEq(stabilityPoolFacet.rewardThreshold(), newThreshold);
    }

    function test_SetRewardThreshold_EmitsEvent() public {
        uint256 newThreshold = 0.05 ether;
        vm.prank(admin);
        vm.expectEmit(false, false, false, true);
        emit RewardThresholdSet(newThreshold);
        stabilityPoolFacet.setRewardThreshold(newThreshold);
    }

    function test_SetRewardThreshold_RevertNotAdmin() public {
        vm.prank(user1);
        vm.expectRevert("Manager: Caller is not admin");
        stabilityPoolFacet.setRewardThreshold(0.05 ether);
    }

    function test_SetSpTreasuryAddress() public {
        address newTreasury = address(0x1234);
        vm.prank(admin);
        stabilityPoolFacet.setSpTreasuryAddress(newTreasury);

        assertEq(stabilityPoolFacet.spTreasuryAddress(), newTreasury);
    }

    function test_SetSpTreasuryAddress_EmitsEvent() public {
        address newTreasury = address(0x1234);
        vm.prank(admin);
        vm.expectEmit(true, false, false, true);
        emit SpTreasuryAddressSet(newTreasury);
        stabilityPoolFacet.setSpTreasuryAddress(newTreasury);
    }

    function test_SetSpTreasuryAddress_RevertZeroAddress() public {
        vm.prank(admin);
        vm.expectRevert("StabilityPool: zero address");
        stabilityPoolFacet.setSpTreasuryAddress(address(0));
    }

    function test_SetSpTreasuryAddress_RevertNotAdmin() public {
        vm.prank(user1);
        vm.expectRevert("Manager: Caller is not admin");
        stabilityPoolFacet.setSpTreasuryAddress(address(0x1234));
    }

    // ==================
    // View helper tests
    // ==================

    function test_GetDepositedLUSD() public {
        uint256 amount = 1000e18;

        lusdToken.mint(user1, amount);
        vm.prank(user1);
        lusdToken.approve(address(diamond), amount);
        vm.prank(user1);
        stabilityPoolFacet.depositToPool(amount);

        assertEq(stabilityPoolFacet.getDepositedLUSD(), amount);
    }

    function test_GetPendingETHReward() public {
        uint256 ethReward = 1 ether;
        mockStabilityPool.setETHGain(address(diamond), ethReward);

        assertEq(stabilityPoolFacet.getPendingETHReward(), ethReward);
    }

    function test_GetPendingLQTYReward() public {
        uint256 lqtyReward = 200e18;
        mockStabilityPool.setLQTYGain(address(diamond), lqtyReward);

        assertEq(stabilityPoolFacet.getPendingLQTYReward(), lqtyReward);
    }

    // ==================
    // Reentrancy test
    // ==================

    function test_Deposit_ReentrancyGuard() public {
        uint256 amount = 1000e18;
        lusdToken.mint(user1, amount);
        vm.prank(user1);
        lusdToken.approve(address(diamond), amount);
        vm.prank(user1);
        stabilityPoolFacet.depositToPool(amount);

        // Second deposit should work fine (nonReentrant resets)
        lusdToken.mint(user1, amount);
        vm.prank(user1);
        lusdToken.approve(address(diamond), amount);
        vm.prank(user1);
        stabilityPoolFacet.depositToPool(amount);

        assertEq(stabilityPoolFacet.totalPrincipalInPool(), 2 * amount);
    }

    // ==================
    // Multiple deposits & withdrawals
    // ==================

    function test_MultipleDepositsAndWithdrawals() public {
        uint256 amount1 = 500e18;
        uint256 amount2 = 300e18;

        // First deposit
        lusdToken.mint(user1, amount1);
        vm.prank(user1);
        lusdToken.approve(address(diamond), amount1);
        vm.prank(user1);
        stabilityPoolFacet.depositToPool(amount1);

        assertEq(stabilityPoolFacet.totalPrincipalInPool(), amount1);

        // Second deposit
        lusdToken.mint(user1, amount2);
        vm.prank(user1);
        lusdToken.approve(address(diamond), amount2);
        vm.prank(user1);
        stabilityPoolFacet.depositToPool(amount2);

        assertEq(
            stabilityPoolFacet.totalPrincipalInPool(),
            amount1 + amount2
        );

        // Partial withdrawal
        vm.prank(user1);
        stabilityPoolFacet.withdrawFromPool(amount1);

        assertEq(stabilityPoolFacet.totalPrincipalInPool(), amount2);

        // Full withdrawal
        vm.prank(user1);
        stabilityPoolFacet.withdrawFromPool(amount2);

        assertEq(stabilityPoolFacet.totalPrincipalInPool(), 0);
        assertEq(lusdToken.balanceOf(user1), amount1 + amount2);
    }
}
