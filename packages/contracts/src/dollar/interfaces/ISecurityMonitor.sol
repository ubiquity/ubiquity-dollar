// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/// @title ISecurityMonitor - Interface for security monitoring of Ubiquity Dollar protocol
/// @notice Monitors for anomalous transfers, price deviations, and triggers emergency pauses
interface ISecurityMonitor {
    // ─── Events ────────────────────────────────────────────────────────────

    /// @notice Emitted when a large transfer is detected
    event LargeTransferDetected(
        address indexed token,
        address indexed from,
        address indexed to,
        uint256 amount,
        uint256 threshold
    );

    /// @notice Emitted when a price deviation is detected
    event PriceDeviationDetected(
        address indexed pool,
        uint256 currentPrice,
        uint256 expectedPrice,
        uint256 deviationBps
    );

    /// @notice Emitted when auto-pause is triggered
    event SecurityPauseTriggered(
        address indexed trigger,
        string reason
    );

    /// @notice Emitted when manual pause is executed
    event ManualPauseExecuted(
        address indexed guardian,
        string reason
    );

    /// @notice Emitted when contracts are unpaused
    event SecurityUnpauseExecuted(address indexed admin);

    /// @notice Emitted when a monitored contract is added
    event MonitoredContractAdded(address indexed contractAddr);

    /// @notice Emitted when a monitored contract is removed
    event MonitoredContractRemoved(address indexed contractAddr);

    /// @notice Emitted when threshold parameters are updated
    event ThresholdsUpdated(
        uint256 transferThreshold,
        uint256 priceDeviationBps,
        uint256 cooldownPeriod
    );

    /// @notice Emitted when an alert is raised
    event SecurityAlert(
        uint8 indexed alertLevel,
        string message,
        address indexed source
    );

    // ─── Enums ─────────────────────────────────────────────────────────────

    /// @notice Alert severity levels
    enum AlertLevel {
        INFO,       // 0 - Informational
        WARNING,    // 1 - Warning, monitoring closely
        CRITICAL,   // 2 - Critical, auto-pause triggered
        EMERGENCY   // 3 - Emergency, manual intervention required
    }

    // ─── Structs ───────────────────────────────────────────────────────────

    /// @notice Configuration for security monitoring thresholds
    struct MonitorConfig {
        uint256 largeTransferThreshold;  // Max allowed transfer in token units (18 decimals)
        uint256 priceDeviationThresholdBps; // Max allowed price deviation in basis points
        uint256 pauseCooldown;            // Min time between auto-pauses in seconds
        uint256 lastPauseTimestamp;       // Timestamp of last auto-pause
        bool autoPauseEnabled;            // Whether auto-pause is active
    }

    /// @notice Records of anomalous activity for a given contract
    struct AnomalyRecord {
        uint256 anomalyCount;
        uint256 lastAnomalyTimestamp;
        AlertLevel highestAlertLevel;
    }

    // ─── View Functions ────────────────────────────────────────────────────

    /// @notice Get the current monitor configuration
    function getMonitorConfig() external view returns (MonitorConfig memory);

    /// @notice Check if a contract is being monitored
    function isMonitored(address contractAddr) external view returns (bool);

    /// @notice Get anomaly record for a contract
    function getAnomalyRecord(address contractAddr) external view returns (AnomalyRecord memory);

    /// @notice Check if protocol is currently paused
    function isPaused() external view returns (bool);

    /// @notice Get the list of monitored contracts
    function getMonitoredContracts() external view returns (address[] memory);

    /// @notice Check if upkeep is needed (for Chainlink Automation compatibility)
    function checkUpkeep(bytes calldata checkData) external view returns (bool upkeepNeeded, bytes memory performData);

    // ─── State-Changing Functions ──────────────────────────────────────────

    /// @notice Perform upkeep (for Chainlink Automation compatibility)
    function performUpkeep(bytes calldata performData) external;

    /// @notice Report a potentially anomalous transfer
    function reportTransfer(address token, address from, address to, uint256 amount) external;

    /// @notice Report a price observation for deviation checking
    function reportPrice(address pool, uint256 currentPrice, uint256 expectedPrice) external;

    /// @notice Manually trigger a security pause (guardian only)
    function triggerPause(string calldata reason) external;

    /// @notice Unpause all contracts (admin only)
    function unpause() external;

    /// @notice Add a contract to the monitored list
    function addMonitoredContract(address contractAddr) external;

    /// @notice Remove a contract from the monitored list
    function removeMonitoredContract(address contractAddr) external;

    /// @notice Update monitoring thresholds
    function setThresholds(
        uint256 transferThreshold,
        uint256 priceDeviationBps,
        uint256 cooldownPeriod
    ) external;

    /// @notice Toggle auto-pause feature
    function setAutoPauseEnabled(bool enabled) external;
}
