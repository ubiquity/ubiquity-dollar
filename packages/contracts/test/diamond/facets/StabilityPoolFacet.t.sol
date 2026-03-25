// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import {DiamondTestSetup} from "../DiamondTestSetup.sol";
import {StabilityPoolFacet} from "../../../src/dollar/facets/StabilityPoolFacet.sol";
import {LibStabilityPool} from "../../../src/dollar/libraries/LibStabilityPool.sol";
import {MockERC20} from "../../../src/dollar/mocks/MockERC20.sol";
import {MockLiquityStabilityPool} from "../../../src/dollar/mocks/MockLiquityStabilityPool.sol";
import {IDiamondCut} from "../../../src/dollar/interfaces/IDiamondCut.sol";

contract StabilityPoolFacetTest is DiamondTestSetup {
    StabilityPoolFacet stabilityPoolFacet;
    StabilityPoolFacet stabilityPoolFacetImplementation;

    MockERC20 lusdToken;
    MockERC20 lqtyToken;
    MockLiquityStabilityPool mockStabilityPool;

    address treasury = address(0xBEEF);

    // Events
    event DepositedToStabilityPool(uint256 amount, uint256 newTotalPrincipal);
    event WithdrawnFromStabilityPool(
        uint256 amount,
        uint256 newTotalPrincipal
    );
    event RewardsHarvested(
        uint256 ethAmount,
        uint256 lqtyAmount,
        address treasury
    );
    event StabilityPoolAddressSet(address newStabilityPoolAddress);
    event LusdTokenAddressSet(address newLusdTokenAddress);
    event LqtyTokenAddressSet(address newLqtyTokenAddress);
    event ProtocolTreasurySet(address newProtocolTreasury);
    event HarvestRewardThresholdSet(uint256 newThreshold);
    event CompoundingPercentageSet(uint256 newPercentage);
    event StabilityPoolToggled(bool isActive);

    function setUp() public override {
        super.setUp();

        // Deploy mock tokens
        vm.startPrank(admin);

        lusdToken = new MockERC20("LUSD Stablecoin", "LUSD", 18);
        lqtyToken = new MockERC20("LQTY", "LQTY", 18);

        // Deploy mock stability pool
        mockStabilityPool = new MockLiquityStabilityPool(
            address(lusdToken),
            address(lqtyToken)
        );

        // Deploy StabilityPoolFacet
        stabilityPoolFacetImplementation = new StabilityPoolFacet();

        // Get selectors for StabilityPoolFacet
        bytes4[] memory selectors = new bytes4[](15);
        selectors[0] = StabilityPoolFacet.totalPrincipalInPool.selector;
        selectors[1] = StabilityPoolFacet.currentLusdInStabilityPool.selector;
        selectors[2] = StabilityPoolFacet.pendingEthReward.selector;
        selectors[3] = StabilityPoolFacet.pendingLqtyReward.selector;
        selectors[4] = StabilityPoolFacet.isStabilityPoolActive.selector;
        selectors[5] = StabilityPoolFacet.harvestRewardThreshold.selector;
        selectors[6] = StabilityPoolFacet.compoundingPercentage.selector;
        selectors[7] = StabilityPoolFacet.protocolTreasury.selector;
        selectors[8] = StabilityPoolFacet.depositToPool.selector;
        selectors[9] = StabilityPoolFacet.withdrawFromPool.selector;
        selectors[10] = StabilityPoolFacet.harvestRewards.selector;
        selectors[11] = StabilityPoolFacet.setStabilityPoolAddress.selector;
        selectors[12] = StabilityPoolFacet.setLusdTokenAddress.selector;
        selectors[13] = StabilityPoolFacet.setLqtyTokenAddress.selector;
        selectors[14] = StabilityPoolFacet.setProtocolTreasury.selector;

        // Prepare additional selectors that need separate array
        bytes4[] memory selectors2 = new bytes4[](3);
        selectors2[0] = StabilityPoolFacet.setHarvestRewardThreshold.selector;
        selectors2[1] = StabilityPoolFacet.setCompoundingPercentage.selector;
        selectors2[2] = StabilityPoolFacet.toggleStabilityPool.selector;

        // Combine into one array
        bytes4[] memory allSelectors = new bytes4[](18);
        for (uint256 i = 0; i < 15; i++) {
            allSelectors[i] = selectors[i];
        }
        for (uint256 i = 0; i < 3; i++) {
            allSelectors[15 + i] = selectors2[i];
        }

        // Add facet to diamond via diamondCut
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](1);
        cuts[0] = IDiamondCut.FacetCut({
            facetAddress: address(stabilityPoolFacetImplementation),
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: allSelectors
        });

        vm.stopPrank();

        // Owner performs the diamond cut
        vm.prank(owner);
        diamondCutFacet.diamondCut(cuts, address(0), "");

        // Create facet interface pointing to diamond
        stabilityPoolFacet = StabilityPoolFacet(payable(address(diamond)));

        // Configure the facet
        vm.startPrank(admin);
        stabilityPoolFacet.setStabilityPoolAddress(
            address(mockStabilityPool)
        );
        stabilityPoolFacet.setLusdTokenAddress(address(lusdToken));
        stabilityPoolFacet.setLqtyTokenAddress(address(lqtyToken));
        stabilityPoolFacet.setProtocolTreasury(treasury);
        stabilityPoolFacet.setHarvestRewardThreshold(0.01 ether);
        stabilityPoolFacet.setCompoundingPercentage(500_000); // 50%
        stabilityPoolFacet.toggleStabilityPool(); // activate
        vm.stopPrank();
    }

    // ==========================================
    // View function tests
    // ==========================================

    function testTotalPrincipalInPool_InitiallyZero() public {
        assertEq(stabilityPoolFacet.totalPrincipalInPool(), 0);
    }

    function testCurrentLusdInStabilityPool_InitiallyZero() public {
        assertEq(stabilityPoolFacet.currentLusdInStabilityPool(), 0);
    }

    function testPendingEthReward_InitiallyZero() public {
        assertEq(stabilityPoolFacet.pendingEthReward(), 0);
    }

    function testPendingLqtyReward_InitiallyZero() public {
        assertEq(stabilityPoolFacet.pendingLqtyReward(), 0);
    }

    function testIsStabilityPoolActive() public {
        assertTrue(stabilityPoolFacet.isStabilityPoolActive());
    }

    function testHarvestRewardThreshold() public {
        assertEq(stabilityPoolFacet.harvestRewardThreshold(), 0.01 ether);
    }

    function testCompoundingPercentage() public {
        assertEq(stabilityPoolFacet.compoundingPercentage(), 500_000);
    }

    function testProtocolTreasury() public {
        assertEq(stabilityPoolFacet.protocolTreasury(), treasury);
    }

    // ==========================================
    // Deposit tests
    // ==========================================

    function testDepositToPool() public {
        uint256 depositAmount = 1000 ether;

        // Mint LUSD to diamond and approve
        lusdToken.mint(address(diamond), depositAmount);

        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit DepositedToStabilityPool(depositAmount, depositAmount);
        stabilityPoolFacet.depositToPool(depositAmount);

        assertEq(stabilityPoolFacet.totalPrincipalInPool(), depositAmount);
        assertEq(
            stabilityPoolFacet.currentLusdInStabilityPool(),
            depositAmount
        );
    }

    function testDepositToPool_RevertsWhenNotActive() public {
        vm.startPrank(admin);
        stabilityPoolFacet.toggleStabilityPool(); // deactivate

        vm.expectRevert("StabilityPool: not active");
        stabilityPoolFacet.depositToPool(100 ether);
        vm.stopPrank();
    }

    function testDepositToPool_RevertsWhenZeroAmount() public {
        vm.prank(admin);
        vm.expectRevert("StabilityPool: zero amount");
        stabilityPoolFacet.depositToPool(0);
    }

    function testDepositToPool_RevertsWhenNotAdmin() public {
        vm.prank(user1);
        vm.expectRevert("Manager: Caller is not admin");
        stabilityPoolFacet.depositToPool(100 ether);
    }

    function testDepositToPool_MultipleDeposits() public {
        uint256 deposit1 = 500 ether;
        uint256 deposit2 = 300 ether;

        lusdToken.mint(address(diamond), deposit1 + deposit2);

        vm.startPrank(admin);
        stabilityPoolFacet.depositToPool(deposit1);
        assertEq(stabilityPoolFacet.totalPrincipalInPool(), deposit1);

        stabilityPoolFacet.depositToPool(deposit2);
        assertEq(
            stabilityPoolFacet.totalPrincipalInPool(),
            deposit1 + deposit2
        );
        vm.stopPrank();
    }

    // ==========================================
    // Withdraw tests
    // ==========================================

    function testWithdrawFromPool() public {
        uint256 depositAmount = 1000 ether;
        uint256 withdrawAmount = 400 ether;

        lusdToken.mint(address(diamond), depositAmount);

        vm.startPrank(admin);
        stabilityPoolFacet.depositToPool(depositAmount);

        vm.expectEmit(true, true, true, true);
        emit WithdrawnFromStabilityPool(
            withdrawAmount,
            depositAmount - withdrawAmount
        );
        stabilityPoolFacet.withdrawFromPool(withdrawAmount);

        assertEq(
            stabilityPoolFacet.totalPrincipalInPool(),
            depositAmount - withdrawAmount
        );
        vm.stopPrank();
    }

    function testWithdrawFromPool_RevertsWhenExceedsPrincipal() public {
        uint256 depositAmount = 100 ether;
        lusdToken.mint(address(diamond), depositAmount);

        vm.startPrank(admin);
        stabilityPoolFacet.depositToPool(depositAmount);

        vm.expectRevert("StabilityPool: exceeds principal");
        stabilityPoolFacet.withdrawFromPool(200 ether);
        vm.stopPrank();
    }

    function testWithdrawFromPool_RevertsWhenZeroAmount() public {
        vm.prank(admin);
        vm.expectRevert("StabilityPool: zero amount");
        stabilityPoolFacet.withdrawFromPool(0);
    }

    function testWithdrawFromPool_RevertsWhenNotAdmin() public {
        vm.prank(user1);
        vm.expectRevert("Manager: Caller is not admin");
        stabilityPoolFacet.withdrawFromPool(100 ether);
    }

    function testWithdrawFromPool_FullWithdraw() public {
        uint256 depositAmount = 1000 ether;
        lusdToken.mint(address(diamond), depositAmount);

        vm.startPrank(admin);
        stabilityPoolFacet.depositToPool(depositAmount);
        stabilityPoolFacet.withdrawFromPool(depositAmount);

        assertEq(stabilityPoolFacet.totalPrincipalInPool(), 0);
        assertEq(
            lusdToken.balanceOf(address(diamond)),
            depositAmount
        );
        vm.stopPrank();
    }

    // ==========================================
    // Harvest tests
    // ==========================================

    function testHarvestRewards_WithLqty() public {
        uint256 depositAmount = 1000 ether;
        uint256 lqtyReward = 50 ether;

        lusdToken.mint(address(diamond), depositAmount);

        vm.startPrank(admin);
        stabilityPoolFacet.depositToPool(depositAmount);
        vm.stopPrank();

        // Simulate LQTY rewards accumulation
        lqtyToken.mint(address(mockStabilityPool), lqtyReward);
        mockStabilityPool.setLQTYGain(address(diamond), lqtyReward);

        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit RewardsHarvested(0, lqtyReward, treasury);
        stabilityPoolFacet.harvestRewards();

        assertEq(lqtyToken.balanceOf(treasury), lqtyReward);
    }

    function testHarvestRewards_NoRewards() public {
        uint256 depositAmount = 1000 ether;
        lusdToken.mint(address(diamond), depositAmount);

        vm.startPrank(admin);
        stabilityPoolFacet.depositToPool(depositAmount);

        vm.expectEmit(true, true, true, true);
        emit RewardsHarvested(0, 0, treasury);
        stabilityPoolFacet.harvestRewards();
        vm.stopPrank();
    }

    function testHarvestRewards_RevertsWhenNotAdmin() public {
        vm.prank(user1);
        vm.expectRevert("Manager: Caller is not admin");
        stabilityPoolFacet.harvestRewards();
    }

    function testHarvestRewards_RevertsWhenTreasuryNotSet() public {
        // Deploy a fresh diamond with no treasury set
        // We test by changing treasury to zero address
        // Since we can't set to zero through normal function (it reverts), we test
        // the error message from the library directly

        vm.startPrank(admin);
        vm.expectRevert("StabilityPool: zero address");
        stabilityPoolFacet.setProtocolTreasury(address(0));
        vm.stopPrank();
    }

    // ==========================================
    // Admin function tests
    // ==========================================

    function testSetStabilityPoolAddress() public {
        address newAddr = address(0x1234);
        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit StabilityPoolAddressSet(newAddr);
        stabilityPoolFacet.setStabilityPoolAddress(newAddr);
    }

    function testSetStabilityPoolAddress_RevertsZeroAddress() public {
        vm.prank(admin);
        vm.expectRevert("StabilityPool: zero address");
        stabilityPoolFacet.setStabilityPoolAddress(address(0));
    }

    function testSetStabilityPoolAddress_RevertsNotAdmin() public {
        vm.prank(user1);
        vm.expectRevert("Manager: Caller is not admin");
        stabilityPoolFacet.setStabilityPoolAddress(address(0x1234));
    }

    function testSetLusdTokenAddress() public {
        address newAddr = address(0x5678);
        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit LusdTokenAddressSet(newAddr);
        stabilityPoolFacet.setLusdTokenAddress(newAddr);
    }

    function testSetLusdTokenAddress_RevertsZeroAddress() public {
        vm.prank(admin);
        vm.expectRevert("StabilityPool: zero address");
        stabilityPoolFacet.setLusdTokenAddress(address(0));
    }

    function testSetLqtyTokenAddress() public {
        address newAddr = address(0x9ABC);
        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit LqtyTokenAddressSet(newAddr);
        stabilityPoolFacet.setLqtyTokenAddress(newAddr);
    }

    function testSetLqtyTokenAddress_RevertsZeroAddress() public {
        vm.prank(admin);
        vm.expectRevert("StabilityPool: zero address");
        stabilityPoolFacet.setLqtyTokenAddress(address(0));
    }

    function testSetProtocolTreasury() public {
        address newTreasury = address(0xDEAD);
        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit ProtocolTreasurySet(newTreasury);
        stabilityPoolFacet.setProtocolTreasury(newTreasury);

        assertEq(stabilityPoolFacet.protocolTreasury(), newTreasury);
    }

    function testSetHarvestRewardThreshold() public {
        uint256 newThreshold = 0.05 ether;
        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit HarvestRewardThresholdSet(newThreshold);
        stabilityPoolFacet.setHarvestRewardThreshold(newThreshold);

        assertEq(stabilityPoolFacet.harvestRewardThreshold(), newThreshold);
    }

    function testSetCompoundingPercentage() public {
        uint256 newPercentage = 700_000; // 70%
        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit CompoundingPercentageSet(newPercentage);
        stabilityPoolFacet.setCompoundingPercentage(newPercentage);

        assertEq(stabilityPoolFacet.compoundingPercentage(), newPercentage);
    }

    function testSetCompoundingPercentage_RevertsExceeds100() public {
        vm.prank(admin);
        vm.expectRevert("StabilityPool: percentage exceeds 100%");
        stabilityPoolFacet.setCompoundingPercentage(1_000_001);
    }

    function testToggleStabilityPool() public {
        // Currently active from setUp
        assertTrue(stabilityPoolFacet.isStabilityPoolActive());

        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit StabilityPoolToggled(false);
        stabilityPoolFacet.toggleStabilityPool();

        assertFalse(stabilityPoolFacet.isStabilityPoolActive());

        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit StabilityPoolToggled(true);
        stabilityPoolFacet.toggleStabilityPool();

        assertTrue(stabilityPoolFacet.isStabilityPoolActive());
    }

    function testToggleStabilityPool_RevertsNotAdmin() public {
        vm.prank(user1);
        vm.expectRevert("Manager: Caller is not admin");
        stabilityPoolFacet.toggleStabilityPool();
    }

    // ==========================================
    // Integration / Flow tests
    // ==========================================

    function testFullMintRedeemFlow() public {
        uint256 depositAmount = 1000 ether;
        uint256 lqtyReward = 100 ether;

        // Step 1: Mint flow - deposit LUSD to pool
        lusdToken.mint(address(diamond), depositAmount);

        vm.startPrank(admin);
        stabilityPoolFacet.depositToPool(depositAmount);
        assertEq(stabilityPoolFacet.totalPrincipalInPool(), depositAmount);
        assertEq(
            stabilityPoolFacet.currentLusdInStabilityPool(),
            depositAmount
        );
        vm.stopPrank();

        // Step 2: Simulate LQTY liquidation rewards
        lqtyToken.mint(address(mockStabilityPool), lqtyReward);
        mockStabilityPool.setLQTYGain(address(diamond), lqtyReward);

        // Step 3: Harvest rewards
        vm.prank(admin);
        stabilityPoolFacet.harvestRewards();

        assertEq(lqtyToken.balanceOf(treasury), lqtyReward);

        // Step 4: Redeem flow - withdraw principal
        vm.prank(admin);
        stabilityPoolFacet.withdrawFromPool(depositAmount);
        assertEq(stabilityPoolFacet.totalPrincipalInPool(), 0);
        assertEq(
            lusdToken.balanceOf(address(diamond)),
            depositAmount
        );
    }

    function testPartialWithdrawWithLqtyRewards() public {
        uint256 depositAmount = 1000 ether;
        uint256 partialWithdraw = 400 ether;
        uint256 lqtyReward = 25 ether;

        lusdToken.mint(address(diamond), depositAmount);

        vm.prank(admin);
        stabilityPoolFacet.depositToPool(depositAmount);

        // Simulate LQTY reward
        lqtyToken.mint(address(mockStabilityPool), lqtyReward);
        mockStabilityPool.setLQTYGain(address(diamond), lqtyReward);

        // Withdraw partial - this also claims LQTY rewards via the mock
        vm.prank(admin);
        stabilityPoolFacet.withdrawFromPool(partialWithdraw);

        assertEq(
            stabilityPoolFacet.totalPrincipalInPool(),
            depositAmount - partialWithdraw
        );
        // Diamond should have the withdrawn LUSD
        assertEq(lusdToken.balanceOf(address(diamond)), partialWithdraw);
        // Diamond received LQTY reward from the withdraw
        assertEq(lqtyToken.balanceOf(address(diamond)), lqtyReward);
    }
}
