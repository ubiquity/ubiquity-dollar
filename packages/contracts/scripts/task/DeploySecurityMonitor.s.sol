// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {SecurityMonitor} from "../../src/dollar/security/SecurityMonitor.sol";
import {LibAccessControl} from "../../src/dollar/libraries/LibAccessControl.sol";

/// @title DeploySecurityMonitor - Deployment script for SecurityMonitor contract
/// @notice Deploys and configures the SecurityMonitor with initial parameters
contract DeploySecurityMonitor is Script {
    // Default thresholds (configurable via env vars)
    uint256 constant DEFAULT_TRANSFER_THRESHOLD = 100_000e18;   // 100k tokens
    uint256 constant DEFAULT_PRICE_DEVIATION_BPS = 500;          // 5%
    uint256 constant DEFAULT_COOLDOWN_PERIOD = 1 hours;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address admin = vm.envOr("ADMIN_ADDRESS", vm.addr(deployerPrivateKey));

        uint256 transferThreshold = vm.envOr(
            "TRANSFER_THRESHOLD",
            DEFAULT_TRANSFER_THRESHOLD
        );
        uint256 priceDeviationBps = vm.envOr(
            "PRICE_DEVIATION_BPS",
            DEFAULT_PRICE_DEVIATION_BPS
        );
        uint256 cooldownPeriod = vm.envOr(
            "COOLDOWN_PERIOD",
            DEFAULT_COOLDOWN_PERIOD
        );

        vm.startBroadcast(deployerPrivateKey);

        // Deploy SecurityMonitor
        SecurityMonitor monitor = new SecurityMonitor();
        console.log("SecurityMonitor deployed at:", address(monitor));

        // Initialize with thresholds
        monitor.initialize(transferThreshold, priceDeviationBps, cooldownPeriod);
        console.log("SecurityMonitor initialized with thresholds:");
        console.log("  Transfer threshold:", transferThreshold);
        console.log("  Price deviation (bps):", priceDeviationBps);
        console.log("  Cooldown period:", cooldownPeriod);

        vm.stopBroadcast();

        // Log deployment info
        console.log("--- Deployment Complete ---");
        console.log("Admin:", admin);
        console.log("SecurityMonitor:", address(monitor));
    }
}
