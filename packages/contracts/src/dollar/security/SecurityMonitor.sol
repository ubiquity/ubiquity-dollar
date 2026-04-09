// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ISecurityMonitor} from "../interfaces/ISecurityMonitor.sol";
import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import {LibAccessControl} from "../libraries/LibAccessControl.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";
import {PauseGuardian} from "./PauseGuardian.sol";

/// @title SecurityMonitor - Main security monitoring contract for Ubiquity Dollar protocol
/// @notice Monitors for anomalous transfers, price deviations, and triggers emergency pauses
/// @dev Compatible with Chainlink Automation for automated monitoring via checkUpkeep/performUpkeep
contract SecurityMonitor is ISecurityMonitor, Modifiers {
    // ─── Storage ───────────────────────────────────────────────────────────

    bytes32 public constant GUARDIAN_ROLE = keccak256("PAUSE_GUARDIAN_ROLE");

    /// @notice Monitor configuration
    MonitorConfig public monitorConfig;

    /// @notice List of monitored contract addresses
    address[] public monitoredContracts;
    /// @notice Mapping for quick lookup of monitored status
    mapping(address => bool) public isMonitoredMap;

    /// @notice Anomaly records per contract
    mapping(address => AnomalyRecord) public anomalyRecords;

    /// @notice Tracked token balances for anomaly detection
    mapping(address => uint256) public lastKnownBalances;

    /// @notice Whether the protocol is currently paused
    bool public protocolPaused;

    // ─── Constructor / Initializer ─────────────────────────────────────────

    /// @notice Initializes the monitor with default thresholds
    /// @param _transferThreshold Max allowed single transfer (18 decimals)
    /// @param _priceDeviationBps Max allowed price deviation (basis points, e.g. 500 = 5%)
    /// @param _cooldownPeriod Min time between auto-pauses (seconds)
    function initialize(
        uint256 _transferThreshold,
        uint256 _priceDeviationBps,
        uint256 _cooldownPeriod
    ) external onlyAdmin {
        require(monitorConfig.largeTransferThreshold == 0, "SecurityMonitor: already initialized");
        monitorConfig = MonitorConfig({
            largeTransferThreshold: _transferThreshold,
            priceDeviationThresholdBps: _priceDeviationBps,
            pauseCooldown: _cooldownPeriod,
            lastPauseTimestamp: 0,
            autoPauseEnabled: true
        });
    }

    // ─── Chainlink Automation Interface ────────────────────────────────────

    /// @inheritdoc ISecurityMonitor
    function checkUpkeep(
        bytes calldata /* checkData */
    ) external view override returns (bool upkeepNeeded, bytes memory performData) {
        if (protocolPaused) {
            return (false, "");
        }

        // Check for balance anomalies on monitored contracts
        uint256 anomalyCount;
        for (uint256 i = 0; i < monitoredContracts.length; i++) {
            address token = store.dollarTokenAddress;
            if (token == address(0)) continue;

            uint256 currentBalance = IERC20(token).balanceOf(monitoredContracts[i]);
            uint256 lastBalance = lastKnownBalances[monitoredContracts[i]];

            if (lastBalance > 0 && currentBalance < lastBalance / 2) {
                // Balance dropped by more than 50%
                anomalyCount++;
            }
        }

        // Check if any anomaly record has critical level
        for (uint256 i = 0; i < monitoredContracts.length; i++) {
            if (anomalyRecords[monitoredContracts[i]].highestAlertLevel >= AlertLevel.CRITICAL) {
                anomalyCount++;
            }
        }

        if (anomalyCount > 0) {
            return (true, abi.encode(anomalyCount));
        }

        return (false, "");
    }

    /// @inheritdoc ISecurityMonitor
    function performUpkeep(bytes calldata performData) external override {
        require(!protocolPaused, "SecurityMonitor: already paused");

        uint256 anomalyCount = abi.decode(performData, (uint256));
        require(anomalyCount > 0, "SecurityMonitor: no anomalies");

        _triggerAutoPause("Chainlink Automation: anomaly detected");
    }

    // ─── Reporting Functions ───────────────────────────────────────────────

    /// @inheritdoc ISecurityMonitor
    function reportTransfer(
        address token,
        address from,
        address to,
        uint256 amount
    ) external override {
        require(isMonitoredMap[from] || isMonitoredMap[to], "SecurityMonitor: not monitored");

        if (amount >= monitorConfig.largeTransferThreshold) {
            emit LargeTransferDetected(token, from, to, amount, monitorConfig.largeTransferThreshold);
            emit SecurityAlert(uint8(AlertLevel.WARNING), "Large transfer detected", from);

            _recordAnomaly(from, AlertLevel.WARNING);

            // Auto-pause if amount is 10x the threshold
            if (
                monitorConfig.autoPauseEnabled &&
                amount >= monitorConfig.largeTransferThreshold * 10 &&
                !protocolPaused
            ) {
                _triggerAutoPause("Transfer exceeds 10x threshold");
            }
        }
    }

    /// @inheritdoc ISecurityMonitor
    function reportPrice(
        address pool,
        uint256 currentPrice,
        uint256 expectedPrice
    ) external override {
        require(isMonitoredMap[pool], "SecurityMonitor: pool not monitored");
        require(expectedPrice > 0, "SecurityMonitor: zero expected price");

        uint256 deviation;
        if (currentPrice > expectedPrice) {
            deviation = ((currentPrice - expectedPrice) * 10000) / expectedPrice;
        } else {
            deviation = ((expectedPrice - currentPrice) * 10000) / expectedPrice;
        }

        if (deviation >= monitorConfig.priceDeviationThresholdBps) {
            emit PriceDeviationDetected(pool, currentPrice, expectedPrice, deviation);

            AlertLevel level = deviation >= monitorConfig.priceDeviationThresholdBps * 3
                ? AlertLevel.CRITICAL
                : AlertLevel.WARNING;

            emit SecurityAlert(uint8(level), "Price deviation detected", pool);
            _recordAnomaly(pool, level);

            if (
                monitorConfig.autoPauseEnabled &&
                level == AlertLevel.CRITICAL &&
                !protocolPaused
            ) {
                _triggerAutoPause("Critical price deviation");
            }
        }
    }

    // ─── Pause Functions ───────────────────────────────────────────────────

    /// @inheritdoc ISecurityMonitor
    function triggerPause(string calldata reason) external override {
        require(
            LibAccessControl._hasRole(GUARDIAN_ROLE, msg.sender),
            "SecurityMonitor: not guardian"
        );
        require(!protocolPaused, "SecurityMonitor: already paused");

        protocolPaused = true;
        store.paused = true;
        emit SecurityPauseTriggered(msg.sender, reason);
        emit ManualPauseExecuted(msg.sender, reason);
    }

    /// @inheritdoc ISecurityMonitor
    function unpause() external override onlyAdmin {
        require(protocolPaused, "SecurityMonitor: not paused");

        protocolPaused = false;
        store.paused = false;

        // Reset anomaly records on unpause
        for (uint256 i = 0; i < monitoredContracts.length; i++) {
            delete anomalyRecords[monitoredContracts[i]];
        }

        emit SecurityUnpauseExecuted(msg.sender);
    }

    // ─── Configuration Functions ───────────────────────────────────────────

    /// @inheritdoc ISecurityMonitor
    function addMonitoredContract(address contractAddr) external override onlyAdmin {
        require(contractAddr != address(0), "SecurityMonitor: zero address");
        require(!isMonitoredMap[contractAddr], "SecurityMonitor: already monitored");

        isMonitoredMap[contractAddr] = true;
        monitoredContracts.push(contractAddr);

        // Snapshot initial balance
        address token = store.dollarTokenAddress;
        if (token != address(0)) {
            lastKnownBalances[contractAddr] = IERC20(token).balanceOf(contractAddr);
        }

        emit MonitoredContractAdded(contractAddr);
    }

    /// @inheritdoc ISecurityMonitor
    function removeMonitoredContract(address contractAddr) external override onlyAdmin {
        require(isMonitoredMap[contractAddr], "SecurityMonitor: not monitored");

        isMonitoredMap[contractAddr] = false;

        // Remove from array by swapping with last element
        for (uint256 i = 0; i < monitoredContracts.length; i++) {
            if (monitoredContracts[i] == contractAddr) {
                monitoredContracts[i] = monitoredContracts[monitoredContracts.length - 1];
                monitoredContracts.pop();
                break;
            }
        }

        delete anomalyRecords[contractAddr];
        delete lastKnownBalances[contractAddr];

        emit MonitoredContractRemoved(contractAddr);
    }

    /// @inheritdoc ISecurityMonitor
    function setThresholds(
        uint256 transferThreshold,
        uint256 priceDeviationBps,
        uint256 cooldownPeriod
    ) external override onlyAdmin {
        monitorConfig.largeTransferThreshold = transferThreshold;
        monitorConfig.priceDeviationThresholdBps = priceDeviationBps;
        monitorConfig.pauseCooldown = cooldownPeriod;

        emit ThresholdsUpdated(transferThreshold, priceDeviationBps, cooldownPeriod);
    }

    /// @inheritdoc ISecurityMonitor
    function setAutoPauseEnabled(bool enabled) external override onlyAdmin {
        monitorConfig.autoPauseEnabled = enabled;
    }

    // ─── View Functions ────────────────────────────────────────────────────

    /// @inheritdoc ISecurityMonitor
    function getMonitorConfig() external view override returns (MonitorConfig memory) {
        return monitorConfig;
    }

    /// @inheritdoc ISecurityMonitor
    function isMonitored(address contractAddr) external view override returns (bool) {
        return isMonitoredMap[contractAddr];
    }

    /// @inheritdoc ISecurityMonitor
    function getAnomalyRecord(address contractAddr) external view override returns (AnomalyRecord memory) {
        return anomalyRecords[contractAddr];
    }

    /// @inheritdoc ISecurityMonitor
    function isPaused() external view override returns (bool) {
        return protocolPaused;
    }

    /// @inheritdoc ISecurityMonitor
    function getMonitoredContracts() external view override returns (address[] memory) {
        return monitoredContracts;
    }

    /// @notice Update tracked balances for all monitored contracts (callable by anyone)
    function snapshotBalances() external {
        address token = store.dollarTokenAddress;
        require(token != address(0), "SecurityMonitor: no token");

        for (uint256 i = 0; i < monitoredContracts.length; i++) {
            lastKnownBalances[monitoredContracts[i]] = IERC20(token).balanceOf(monitoredContracts[i]);
        }
    }

    // ─── Internal Functions ────────────────────────────────────────────────

    /// @dev Record an anomaly for a monitored contract
    function _recordAnomaly(address contractAddr, AlertLevel level) internal {
        AnomalyRecord storage record = anomalyRecords[contractAddr];
        record.anomalyCount++;
        record.lastAnomalyTimestamp = block.timestamp;

        if (uint8(level) > uint8(record.highestAlertLevel)) {
            record.highestAlertLevel = level;
        }
    }

    /// @dev Trigger automatic pause with cooldown check
    function _triggerAutoPause(string memory reason) internal {
        if (
            monitorConfig.lastPauseTimestamp != 0 &&
            block.timestamp < monitorConfig.lastPauseTimestamp + monitorConfig.pauseCooldown
        ) {
            // Still in cooldown period
            emit SecurityAlert(uint8(AlertLevel.WARNING), "Auto-pause skipped: cooldown active", address(this));
            return;
        }

        monitorConfig.lastPauseTimestamp = block.timestamp;
        protocolPaused = true;
        store.paused = true;

        emit SecurityPauseTriggered(address(this), reason);
        emit SecurityAlert(uint8(AlertLevel.EMERGENCY), reason, address(this));
    }
}
