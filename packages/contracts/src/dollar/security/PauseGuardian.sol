// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {ISecurityMonitor} from "../interfaces/ISecurityMonitor.sol";
import {LibAppStorage} from "../libraries/LibAppStorage.sol";
import {LibAccessControl} from "../libraries/LibAccessControl.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

/// @title PauseGuardian - Emergency pause functionality for Ubiquity Dollar protocol
/// @notice Allows guardians and the security monitor to pause all protocol operations
contract PauseGuardian is Modifiers {
    /// @notice Emitted when the pause guardian role is granted
    event PauseGuardianGranted(address indexed guardian);
    /// @notice Emitted when the pause guardian role is revoked
    event PauseGuardianRevoked(address indexed guardian);

    bytes32 public constant GUARDIAN_ROLE = keccak256("PAUSE_GUARDIAN_ROLE");
    bytes32 public constant SECURITY_MONITOR_ROLE = keccak256("SECURITY_MONITOR_ROLE");

    /// @notice Pause all protocol operations (guardian or security monitor only)
    /// @param reason Human-readable reason for the pause
    function pause(string calldata reason) external {
        require(
            LibAccessControl._hasRole(GUARDIAN_ROLE, msg.sender) ||
            LibAccessControl._hasRole(SECURITY_MONITOR_ROLE, msg.sender),
            "PauseGuardian: unauthorized"
        );
        _pause(reason);
    }

    /// @notice Unpause all protocol operations (admin only)
    function unpause() external onlyAdmin {
        _unpause();
    }

    /// @notice Check if protocol is paused
    function paused() external view returns (bool) {
        return store.paused;
    }

    /// @notice Internal pause implementation
    function _pause(string memory reason) internal {
        require(!store.paused, "PauseGuardian: already paused");
        store.paused = true;
        emit ISecurityMonitor.SecurityPauseTriggered(msg.sender, reason);
    }

    /// @notice Internal unpause implementation
    function _unpause() internal {
        require(store.paused, "PauseGuardian: not paused");
        store.paused = false;
        emit ISecurityMonitor.SecurityUnpauseExecuted(msg.sender);
    }

    /// @notice Modifier to prevent execution when paused
    modifier whenNotPaused() {
        require(!store.paused, "PauseGuardian: paused");
        _;
    }
}
