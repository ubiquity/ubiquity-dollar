// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {DiamondTestSetup} from "../DiamondTestSetup.sol";
import {StabilityPoolFacet} from "../../../src/dollar/facets/StabilityPoolFacet.sol";
import {DiamondCutFacet} from "../../../src/dollar/facets/DiamondCutFacet.sol";
import {LibStabilityPool} from "../../../src/dollar/libraries/LibStabilityPool.sol";
import {MockERC20} from "../../../src/dollar/mocks/MockERC20.sol";
import {MockLiquityStabilityPool} from "../../../src/dollar/mocks/MockLiquityStabilityPool.sol";

contract StabilityPoolFacetTest is DiamondTestSetup {
    StabilityPoolFacet stabilityPoolFacet;

    MockERC20 lusdToken;
    MockERC20 lqtyToken;
    MockLiquityStabilityPool mockStabilityPool;

    address treasury = address(0xBEEF);

    // Events (mirror library events for expectEmit)
    event DepositedToStabilityPool(uint256 amount);
    event WithdrawnFromStabilityPool(uint256 amount);
    event GainsHarvested(uint256 ethGain, uint256 lqtyGain, address treasury);
    event StabilityPoolAddressSet(address stabilityPool);
    event LusdTokenAddressSet(address lusdToken);
    event LqtyTokenAddressSet(address lqtyToken);
    event ProtocolTreasurySet(address treasury);
    event FrontEndTagSet(address frontEndTag);

    function setUp() public override {
        super.setUp();

        vm.startPrank(admin);

        // Deploy mock tokens
        lusdToken = new MockERC20("LUSD", "LUSD", 18);
        lqtyToken = new MockERC20("LQTY", "LQTY", 18);

        // Deploy mock Liquity Stability Pool
        mockStabilityPool = new MockLiquityStabilityPool(
            address(lusdToken),
            address(lqtyToken)
        );

        // Deploy StabilityPoolFacet and add to diamond
        StabilityPoolFacet stabilityPoolFacetImplementation = new StabilityPoolFacet();
        bytes4[] memory selectors = getSelectorsFromAbi(
            "/out/StabilityPoolFacet.sol/StabilityPoolFacet.json"
        );

        FacetCut[] memory cuts = new FacetCut[](1);
        cuts[0] = FacetCut({
            facetAddress: address(stabilityPoolFacetImplementation),
            action: FacetCutAction.Add,
            functionSelectors: selectors
        });

        vm.stopPrank();

        // Diamond cut must be done by owner
        vm.prank(owner);
        DiamondCutFacet(address(diamond)).diamondCut(cuts, address(0), "");

        // Create typed reference to diamond
        stabilityPoolFacet = StabilityPoolFacet(payable(address(diamond)));

        // Configure the facet
        vm.startPrank(admin);
        stabilityPoolFacet.setStabilityPoolAddress(
            address(mockStabilityPool)
        );
        stabilityPoolFacet.setLusdTokenAddress(address(lusdToken));
        stabilityPoolFacet.setLqtyTokenAddress(address(lqtyToken));
        stabilityPoolFacet.setProtocolTreasury(treasury);
        vm.stopPrank();
    }

    // =============================
    // Configuration tests
    // =============================

    function testSetStabilityPoolAddress() public {
        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit StabilityPoolAddressSet(address(0x1234));
        stabilityPoolFacet.setStabilityPoolAddress(address(0x1234));
    }

    function testSetStabilityPoolAddressRevertsOnZero() public {
        vm.prank(admin);
        vm.expectRevert("StabilityPool: zero address");
        stabilityPoolFacet.setStabilityPoolAddress(address(0));
    }

    function testSetLusdTokenAddress() public {
        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit LusdTokenAddressSet(address(0x5678));
        stabilityPoolFacet.setLusdTokenAddress(address(0x5678));
    }

    function testSetLusdTokenAddressRevertsOnZero() public {
        vm.prank(admin);
        vm.expectRevert("StabilityPool: zero address");
        stabilityPoolFacet.setLusdTokenAddress(address(0));
    }

    function testSetLqtyTokenAddress() public {
        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit LqtyTokenAddressSet(address(0x9ABC));
        stabilityPoolFacet.setLqtyTokenAddress(address(0x9ABC));
    }

    function testSetLqtyTokenAddressRevertsOnZero() public {
        vm.prank(admin);
        vm.expectRevert("StabilityPool: zero address");
        stabilityPoolFacet.setLqtyTokenAddress(address(0));
    }

    function testSetProtocolTreasury() public {
        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit ProtocolTreasurySet(address(0xDEAD));
        stabilityPoolFacet.setProtocolTreasury(address(0xDEAD));
    }

    function testSetProtocolTreasuryRevertsOnZero() public {
        vm.prank(admin);
        vm.expectRevert("StabilityPool: zero address");
        stabilityPoolFacet.setProtocolTreasury(address(0));
    }

    function testSetFrontEndTag() public {
        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit FrontEndTagSet(address(0xFACE));
        stabilityPoolFacet.setFrontEndTag(address(0xFACE));
    }

    // =============================
    // Access control tests
    // =============================

    function testDepositRevertsForNonAdmin() public {
        vm.prank(user1);
        vm.expectRevert("Manager: Caller is not admin");
        stabilityPoolFacet.depositToStabilityPool(1000e18);
    }

    function testWithdrawRevertsForNonAdmin() public {
        vm.prank(user1);
        vm.expectRevert("Manager: Caller is not admin");
        stabilityPoolFacet.withdrawFromStabilityPool(1000e18);
    }

    function testHarvestRevertsForNonAdmin() public {
        vm.prank(user1);
        vm.expectRevert("Manager: Caller is not admin");
        stabilityPoolFacet.harvestGains();
    }

    function testSetStabilityPoolAddressRevertsForNonAdmin() public {
        vm.prank(user1);
        vm.expectRevert("Manager: Caller is not admin");
        stabilityPoolFacet.setStabilityPoolAddress(address(0x1));
    }

    // =============================
    // Deposit tests
    // =============================

    function testDepositToPool() public {
        uint256 depositAmount = 10_000e18;

        // Mint LUSD to the diamond
        lusdToken.mint(address(diamond), depositAmount);

        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit DepositedToStabilityPool(depositAmount);
        stabilityPoolFacet.depositToStabilityPool(depositAmount);

        // Verify state
        assertEq(stabilityPoolFacet.getPoolBalance(), depositAmount);
        assertEq(stabilityPoolFacet.getTotalPrincipal(), depositAmount);
    }

    function testDepositRevertsOnZeroAmount() public {
        vm.prank(admin);
        vm.expectRevert("StabilityPool: zero deposit");
        stabilityPoolFacet.depositToStabilityPool(0);
    }

    function testDepositRevertsOnInsufficientBalance() public {
        vm.prank(admin);
        vm.expectRevert("StabilityPool: insufficient LUSD");
        stabilityPoolFacet.depositToStabilityPool(1000e18);
    }

    function testMultipleDeposits() public {
        uint256 first = 5_000e18;
        uint256 second = 3_000e18;

        lusdToken.mint(address(diamond), first + second);

        vm.startPrank(admin);
        stabilityPoolFacet.depositToStabilityPool(first);
        stabilityPoolFacet.depositToStabilityPool(second);
        vm.stopPrank();

        assertEq(stabilityPoolFacet.getTotalPrincipal(), first + second);
        assertEq(stabilityPoolFacet.getPoolBalance(), first + second);
    }

    // =============================
    // Withdrawal tests
    // =============================

    function testWithdrawFromPool() public {
        uint256 depositAmount = 10_000e18;
        uint256 withdrawAmount = 4_000e18;

        // Deposit first
        lusdToken.mint(address(diamond), depositAmount);
        vm.prank(admin);
        stabilityPoolFacet.depositToStabilityPool(depositAmount);

        // Withdraw
        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit WithdrawnFromStabilityPool(withdrawAmount);
        stabilityPoolFacet.withdrawFromStabilityPool(withdrawAmount);

        // Verify state
        assertEq(
            stabilityPoolFacet.getPoolBalance(),
            depositAmount - withdrawAmount
        );
        assertEq(
            stabilityPoolFacet.getTotalPrincipal(),
            depositAmount - withdrawAmount
        );

        // LUSD should be back in the diamond
        assertEq(lusdToken.balanceOf(address(diamond)), withdrawAmount);
    }

    function testWithdrawRevertsOnZeroAmount() public {
        vm.prank(admin);
        vm.expectRevert("StabilityPool: zero withdrawal");
        stabilityPoolFacet.withdrawFromStabilityPool(0);
    }

    function testWithdrawRevertsOnExcessAmount() public {
        uint256 depositAmount = 5_000e18;

        lusdToken.mint(address(diamond), depositAmount);
        vm.prank(admin);
        stabilityPoolFacet.depositToStabilityPool(depositAmount);

        vm.prank(admin);
        vm.expectRevert("StabilityPool: amount exceeds deposit");
        stabilityPoolFacet.withdrawFromStabilityPool(depositAmount + 1);
    }

    function testFullWithdrawal() public {
        uint256 depositAmount = 10_000e18;

        lusdToken.mint(address(diamond), depositAmount);
        vm.prank(admin);
        stabilityPoolFacet.depositToStabilityPool(depositAmount);

        vm.prank(admin);
        stabilityPoolFacet.withdrawFromStabilityPool(depositAmount);

        assertEq(stabilityPoolFacet.getPoolBalance(), 0);
        assertEq(stabilityPoolFacet.getTotalPrincipal(), 0);
        assertEq(lusdToken.balanceOf(address(diamond)), depositAmount);
    }

    // =============================
    // Harvest tests
    // =============================

    function testHarvestETHGains() public {
        uint256 depositAmount = 10_000e18;
        uint256 ethGain = 1 ether;

        // Deposit LUSD
        lusdToken.mint(address(diamond), depositAmount);
        vm.prank(admin);
        stabilityPoolFacet.depositToStabilityPool(depositAmount);

        // Simulate ETH gains
        vm.deal(address(mockStabilityPool), ethGain);
        mockStabilityPool.setETHGain(address(diamond), ethGain);

        // Record treasury balance before harvest
        uint256 treasuryBalanceBefore = treasury.balance;

        // Harvest
        vm.prank(admin);
        stabilityPoolFacet.harvestGains();

        // ETH should have been sent to treasury
        assertEq(treasury.balance - treasuryBalanceBefore, ethGain);
        assertEq(stabilityPoolFacet.getETHGain(), 0);
    }

    function testHarvestLQTYGains() public {
        uint256 depositAmount = 10_000e18;
        uint256 lqtyGain = 500e18;

        // Deposit LUSD
        lusdToken.mint(address(diamond), depositAmount);
        vm.prank(admin);
        stabilityPoolFacet.depositToStabilityPool(depositAmount);

        // Simulate LQTY gains
        lqtyToken.mint(address(mockStabilityPool), lqtyGain);
        mockStabilityPool.setLQTYGain(address(diamond), lqtyGain);

        // Harvest
        vm.prank(admin);
        stabilityPoolFacet.harvestGains();

        // LQTY should have been sent to treasury
        assertEq(lqtyToken.balanceOf(treasury), lqtyGain);
        assertEq(stabilityPoolFacet.getLQTYGain(), 0);
    }

    function testHarvestBothGains() public {
        uint256 depositAmount = 10_000e18;
        uint256 ethGain = 2 ether;
        uint256 lqtyGain = 1_000e18;

        // Deposit
        lusdToken.mint(address(diamond), depositAmount);
        vm.prank(admin);
        stabilityPoolFacet.depositToStabilityPool(depositAmount);

        // Simulate gains
        vm.deal(address(mockStabilityPool), ethGain);
        mockStabilityPool.setETHGain(address(diamond), ethGain);
        lqtyToken.mint(address(mockStabilityPool), lqtyGain);
        mockStabilityPool.setLQTYGain(address(diamond), lqtyGain);

        uint256 treasuryEthBefore = treasury.balance;

        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit GainsHarvested(ethGain, lqtyGain, treasury);
        stabilityPoolFacet.harvestGains();

        assertEq(treasury.balance - treasuryEthBefore, ethGain);
        assertEq(lqtyToken.balanceOf(treasury), lqtyGain);
    }

    function testHarvestRevertsWithNoTreasury() public {
        // Use vm.store to zero out the treasury in diamond storage.
        // The setter rejects address(0), so direct storage manipulation is needed.
        bytes32 baseSlot = bytes32(
            uint256(keccak256("ubiquity.contracts.stability.pool.storage")) - 1
        ) & ~bytes32(uint256(0xff));
        bytes32 treasurySlot = bytes32(uint256(baseSlot) + 3);

        vm.store(address(diamond), treasurySlot, bytes32(0));

        vm.prank(admin);
        vm.expectRevert("StabilityPool: treasury not set");
        stabilityPoolFacet.harvestGains();

        // Restore treasury for subsequent tests
        vm.store(address(diamond), treasurySlot, bytes32(uint256(uint160(treasury))));
    }

    function testWithdrawAlsoHarvestsGains() public {
        uint256 depositAmount = 10_000e18;
        uint256 ethGain = 0.5 ether;
        uint256 lqtyGain = 200e18;

        // Deposit
        lusdToken.mint(address(diamond), depositAmount);
        vm.prank(admin);
        stabilityPoolFacet.depositToStabilityPool(depositAmount);

        // Simulate gains
        vm.deal(address(mockStabilityPool), ethGain);
        mockStabilityPool.setETHGain(address(diamond), ethGain);
        lqtyToken.mint(address(mockStabilityPool), lqtyGain);
        mockStabilityPool.setLQTYGain(address(diamond), lqtyGain);

        uint256 treasuryEthBefore = treasury.balance;

        // Withdraw (should also harvest gains)
        vm.prank(admin);
        stabilityPoolFacet.withdrawFromStabilityPool(1_000e18);

        // Gains should have been forwarded to treasury
        assertEq(treasury.balance - treasuryEthBefore, ethGain);
        assertEq(lqtyToken.balanceOf(treasury), lqtyGain);
    }

    // =============================
    // View function tests
    // =============================

    function testGetPoolBalanceBeforeConfig() public {
        // Deploy a fresh facet without configuration
        // Since the diamond is already configured, test with zero deposit
        assertEq(stabilityPoolFacet.getPoolBalance(), 0);
    }

    function testGetETHGain() public {
        uint256 depositAmount = 5_000e18;
        uint256 ethGain = 0.3 ether;

        lusdToken.mint(address(diamond), depositAmount);
        vm.prank(admin);
        stabilityPoolFacet.depositToStabilityPool(depositAmount);

        mockStabilityPool.setETHGain(address(diamond), ethGain);

        assertEq(stabilityPoolFacet.getETHGain(), ethGain);
    }

    function testGetLQTYGain() public {
        uint256 depositAmount = 5_000e18;
        uint256 lqtyGain = 100e18;

        lusdToken.mint(address(diamond), depositAmount);
        vm.prank(admin);
        stabilityPoolFacet.depositToStabilityPool(depositAmount);

        mockStabilityPool.setLQTYGain(address(diamond), lqtyGain);

        assertEq(stabilityPoolFacet.getLQTYGain(), lqtyGain);
    }

    // =============================
    // Edge case tests
    // =============================

    function testDepositWithdrawDepositCycle() public {
        uint256 amount = 5_000e18;

        // Deposit
        lusdToken.mint(address(diamond), amount);
        vm.prank(admin);
        stabilityPoolFacet.depositToStabilityPool(amount);
        assertEq(stabilityPoolFacet.getTotalPrincipal(), amount);

        // Full withdraw
        vm.prank(admin);
        stabilityPoolFacet.withdrawFromStabilityPool(amount);
        assertEq(stabilityPoolFacet.getTotalPrincipal(), 0);

        // Re-deposit
        vm.prank(admin);
        stabilityPoolFacet.depositToStabilityPool(amount);
        assertEq(stabilityPoolFacet.getTotalPrincipal(), amount);
        assertEq(stabilityPoolFacet.getPoolBalance(), amount);
    }

    function testReentrancyProtection() public {
        // Deploy a malicious contract that tries to re-enter harvestGains
        // when it receives ETH gains
        ReentrancyAttacker attacker = new ReentrancyAttacker(
            address(stabilityPoolFacet)
        );

        // Set attacker as treasury so it receives ETH during harvest
        vm.prank(admin);
        stabilityPoolFacet.setProtocolTreasury(address(attacker));

        // Grant attacker the admin role so its reentrant call passes onlyAdmin
        vm.prank(admin);
        accessControlFacet.grantRole(bytes32(0), address(attacker));

        // Deposit LUSD
        uint256 depositAmount = 10_000e18;
        lusdToken.mint(address(diamond), depositAmount);
        vm.prank(admin);
        stabilityPoolFacet.depositToStabilityPool(depositAmount);

        // Simulate ETH gains so treasury (attacker) receives ETH
        uint256 ethGain = 1 ether;
        vm.deal(address(mockStabilityPool), ethGain);
        mockStabilityPool.setETHGain(address(diamond), ethGain);

        // Harvest should revert: attacker's receive() tries to re-enter,
        // which triggers ReentrancyGuard. The inner revert causes the ETH
        // transfer to fail, surfacing as "StabilityPool: ETH transfer failed".
        vm.prank(admin);
        vm.expectRevert("StabilityPool: ETH transfer failed");
        stabilityPoolFacet.harvestGains();

        // Restore treasury
        vm.prank(admin);
        stabilityPoolFacet.setProtocolTreasury(treasury);
    }

    function testWithdrawAfterLiquidationLoss() public {
        uint256 depositAmount = 10_000e18;

        // Deposit LUSD
        lusdToken.mint(address(diamond), depositAmount);
        vm.prank(admin);
        stabilityPoolFacet.depositToStabilityPool(depositAmount);

        // Simulate 20% liquidation loss
        mockStabilityPool.setLossRatio(2000); // 20% loss in bps

        // Compounded deposit should be 8000e18
        assertEq(stabilityPoolFacet.getPoolBalance(), 8_000e18);
        assertEq(stabilityPoolFacet.getTotalPrincipal(), 10_000e18);

        // Withdraw half of compounded (4000e18)
        vm.prank(admin);
        stabilityPoolFacet.withdrawFromStabilityPool(4_000e18);

        // Principal should be reduced pro-rata: 10000 * (4000/8000) = 5000 removed
        assertEq(stabilityPoolFacet.getTotalPrincipal(), 5_000e18);

        // Full withdrawal of remaining compounded deposit
        uint256 remaining = stabilityPoolFacet.getPoolBalance();
        vm.prank(admin);
        stabilityPoolFacet.withdrawFromStabilityPool(remaining);

        // After full withdrawal, principal must be zero
        assertEq(stabilityPoolFacet.getTotalPrincipal(), 0);
    }
}

/**
 * @notice Malicious contract that attempts to re-enter StabilityPoolFacet
 *         when receiving ETH via the harvest gains flow.
 */
contract ReentrancyAttacker {
    address public target;

    constructor(address _target) {
        target = _target;
    }

    receive() external payable {
        // Attempt reentrant call to harvestGains
        StabilityPoolFacet(payable(target)).harvestGains();
    }
}
