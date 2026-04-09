// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {SecurityMonitor} from "../../src/dollar/security/SecurityMonitor.sol";
import {ISecurityMonitor} from "../../src/dollar/interfaces/ISecurityMonitor.sol";
import {PauseGuardian} from "../../src/dollar/security/PauseGuardian.sol";
import {LibAppStorage} from "../../src/dollar/libraries/LibAppStorage.sol";

/// @title Mock ERC20 for testing
contract MockERC20 is IERC20 {
    string public name = "Mock Token";
    string public symbol = "MTK";
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amount) external {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        return _transfer(msg.sender, to, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(allowance[from][msg.sender] >= amount, "ERC20: insufficient allowance");
        allowance[from][msg.sender] -= amount;
        return _transfer(from, to, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal returns (bool) {
        require(balanceOf[from] >= amount, "ERC20: insufficient balance");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}

/// @title SecurityMonitor Test Contract
contract SecurityMonitorTest is Test {
    SecurityMonitor public monitor;
    MockERC20 public token;

    address public admin = address(0x1);
    address public guardian = address(0x2);
    address public alice = address(0x3);
    address public bob = address(0x4);
    address public pool = address(0x5);

    uint256 constant TRANSFER_THRESHOLD = 100_000e18;
    uint256 constant PRICE_DEVIATION_BPS = 500; // 5%
    uint256 constant COOLDOWN_PERIOD = 1 hours;

    function setUp() public {
        vm.startPrank(admin);

        token = new MockERC20();
        monitor = new SecurityMonitor();

        // Set dollar token in app storage
        LibAppStorage.AppStorage storage s = LibAppStorage.appStorage();
        s.dollarTokenAddress = address(token);

        monitor.initialize(TRANSFER_THRESHOLD, PRICE_DEVIATION_BPS, COOLDOWN_PERIOD);

        // Grant guardian role
        // Note: In production this would go through access control
        vm.stopPrank();
    }

    // ─── Initialization Tests ──────────────────────────────────────────────

    function test_initialize_setsThresholds() public view {
        ISecurityMonitor.MonitorConfig memory config = monitor.getMonitorConfig();
        assertEq(config.largeTransferThreshold, TRANSFER_THRESHOLD);
        assertEq(config.priceDeviationThresholdBps, PRICE_DEVIATION_BPS);
        assertEq(config.pauseCooldown, COOLDOWN_PERIOD);
        assertTrue(config.autoPauseEnabled);
    }

    function test_initialState_notPaused() public view {
        assertFalse(monitor.isPaused());
    }

    function test_initialState_notMonitored() public view {
        assertFalse(monitor.isMonitored(alice));
    }

    // ─── Monitored Contract Tests ──────────────────────────────────────────

    function test_addMonitoredContract() public {
        vm.prank(admin);
        monitor.addMonitoredContract(alice);

        assertTrue(monitor.isMonitored(alice));

        address[] memory contracts = monitor.getMonitoredContracts();
        assertEq(contracts.length, 1);
        assertEq(contracts[0], alice);
    }

    function test_revert_addMonitoredContract_zeroAddress() public {
        vm.prank(admin);
        vm.expectRevert("SecurityMonitor: zero address");
        monitor.addMonitoredContract(address(0));
    }

    function test_revert_addMonitoredContract_duplicate() public {
        vm.startPrank(admin);
        monitor.addMonitoredContract(alice);

        vm.expectRevert("SecurityMonitor: already monitored");
        monitor.addMonitoredContract(alice);
        vm.stopPrank();
    }

    function test_removeMonitoredContract() public {
        vm.startPrank(admin);
        monitor.addMonitoredContract(alice);
        monitor.addMonitoredContract(bob);

        monitor.removeMonitoredContract(alice);

        assertFalse(monitor.isMonitored(alice));
        assertTrue(monitor.isMonitored(bob));

        address[] memory contracts = monitor.getMonitoredContracts();
        assertEq(contracts.length, 1);
        vm.stopPrank();
    }

    // ─── Transfer Monitoring Tests ─────────────────────────────────────────

    function test_reportTransfer_emitsLargeTransfer() public {
        vm.prank(admin);
        monitor.addMonitoredContract(alice);

        uint256 largeAmount = TRANSFER_THRESHOLD; // exactly at threshold

        vm.expectEmit(true, true, true, true);
        emit ISecurityMonitor.LargeTransferDetected(
            address(token), alice, bob, largeAmount, TRANSFER_THRESHOLD
        );

        monitor.reportTransfer(address(token), alice, bob, largeAmount);
    }

    function test_reportTransfer_belowThreshold_noEvent() public {
        vm.prank(admin);
        monitor.addMonitoredContract(alice);

        uint256 smallAmount = TRANSFER_THRESHOLD - 1;

        // Should not emit LargeTransferDetected
        vm.recordLogs();
        monitor.reportTransfer(address(token), alice, bob, smallAmount);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            // LargeTransferDetected sig should not appear
            assertNotEq(logs[i].topics[0], keccak256("LargeTransferDetected(address,address,address,uint256,uint256)"));
        }
    }

    function test_reportTransfer_10xTriggersAutoPause() public {
        vm.prank(admin);
        monitor.addMonitoredContract(alice);

        uint256 hugeAmount = TRANSFER_THRESHOLD * 10;

        vm.expectEmit(true, false, false, true);
        emit ISecurityMonitor.SecurityPauseTriggered(
            address(monitor),
            "Transfer exceeds 10x threshold"
        );

        monitor.reportTransfer(address(token), alice, bob, hugeAmount);
        assertTrue(monitor.isPaused());
    }

    function test_reportTransfer_updatesAnomalyRecord() public {
        vm.prank(admin);
        monitor.addMonitoredContract(alice);

        monitor.reportTransfer(address(token), alice, bob, TRANSFER_THRESHOLD);

        ISecurityMonitor.AnomalyRecord memory record = monitor.getAnomalyRecord(alice);
        assertEq(record.anomalyCount, 1);
        assertEq(uint8(record.highestAlertLevel), uint8(ISecurityMonitor.AlertLevel.WARNING));
    }

    // ─── Price Deviation Tests ─────────────────────────────────────────────

    function test_reportPrice_emitsDeviation() public {
        vm.prank(admin);
        monitor.addMonitoredContract(pool);

        uint256 expectedPrice = 1e18;
        uint256 currentPrice = 1.06e18; // 6% deviation > 5% threshold

        vm.expectEmit(true, false, false, true);
        emit ISecurityMonitor.PriceDeviationDetected(
            pool, currentPrice, expectedPrice, 600 // 6% = 600 bps
        );

        monitor.reportPrice(pool, currentPrice, expectedPrice);
    }

    function test_reportPrice_belowThreshold_noEvent() public {
        vm.prank(admin);
        monitor.addMonitoredContract(pool);

        uint256 expectedPrice = 1e18;
        uint256 currentPrice = 1.04e18; // 4% deviation < 5% threshold

        vm.recordLogs();
        monitor.reportPrice(pool, currentPrice, expectedPrice);

        Vm.Log[] memory logs = vm.getRecordedLogs();
        for (uint256 i = 0; i < logs.length; i++) {
            assertNotEq(logs[i].topics[0], keccak256("PriceDeviationDetected(address,uint256,uint256,uint256)"));
        }
    }

    function test_reportPrice_criticalDeviation_autoPauses() public {
        vm.prank(admin);
        monitor.addMonitoredContract(pool);

        uint256 expectedPrice = 1e18;
        uint256 currentPrice = 1.16e18; // 16% deviation > 15% (3x threshold)

        monitor.reportPrice(pool, currentPrice, expectedPrice);
        assertTrue(monitor.isPaused());
    }

    function test_revert_reportPrice_unmonitoredPool() public {
        vm.expectRevert("SecurityMonitor: pool not monitored");
        monitor.reportPrice(pool, 1e18, 1e18);
    }

    function test_revert_reportPrice_zeroExpected() public {
        vm.prank(admin);
        monitor.addMonitoredContract(pool);

        vm.expectRevert("SecurityMonitor: zero expected price");
        monitor.reportPrice(pool, 1e18, 0);
    }

    // ─── Pause/Unpause Tests ───────────────────────────────────────────────

    function test_setThresholds() public {
        vm.prank(admin);
        monitor.setThresholds(50_000e18, 300, 30 minutes);

        ISecurityMonitor.MonitorConfig memory config = monitor.getMonitorConfig();
        assertEq(config.largeTransferThreshold, 50_000e18);
        assertEq(config.priceDeviationThresholdBps, 300);
        assertEq(config.pauseCooldown, 30 minutes);
    }

    function test_setAutoPauseEnabled() public {
        vm.prank(admin);
        monitor.setAutoPauseEnabled(false);

        ISecurityMonitor.MonitorConfig memory config = monitor.getMonitorConfig();
        assertFalse(config.autoPauseEnabled);
    }

    function test_autoPauseDisabled_noPauseOnLargeTransfer() public {
        vm.startPrank(admin);
        monitor.addMonitoredContract(alice);
        monitor.setAutoPauseEnabled(false);
        vm.stopPrank();

        uint256 hugeAmount = TRANSFER_THRESHOLD * 10;
        monitor.reportTransfer(address(token), alice, bob, hugeAmount);

        assertFalse(monitor.isPaused());
    }

    // ─── Cooldown Tests ────────────────────────────────────────────────────

    function test_autoPause_cooldownPreventsRapidPause() public {
        vm.prank(admin);
        monitor.addMonitoredContract(alice);

        // First pause via price deviation
        vm.startPrank(admin);
        monitor.addMonitoredContract(pool);
        vm.stopPrank();

        // Trigger first auto-pause
        monitor.reportPrice(pool, 1.16e18, 1e18);
        assertTrue(monitor.isPaused());

        // Admin unpauses
        vm.prank(admin);
        monitor.unpause();
        assertFalse(monitor.isPaused());

        // Immediately try another auto-pause - should be blocked by cooldown
        monitor.reportPrice(pool, 1.16e18, 1e18);
        assertFalse(monitor.isPaused()); // Still within cooldown

        // After cooldown period, should work
        vm.warp(block.timestamp + COOLDOWN_PERIOD + 1);
        monitor.reportPrice(pool, 1.16e18, 1e18);
        assertTrue(monitor.isPaused());
    }

    // ─── Snapshot Balance Tests ────────────────────────────────────────────

    function test_snapshotBalances() public {
        vm.startPrank(admin);
        monitor.addMonitoredContract(alice);
        token.mint(alice, 1000e18);
        vm.stopPrank();

        monitor.snapshotBalances();

        // Verify balance was recorded (read via lastKnownBalances)
        // We can verify indirectly via checkUpkeep behavior
    }
}
