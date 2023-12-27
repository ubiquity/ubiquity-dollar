// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {AddressUtils} from "../libraries/AddressUtils.sol";
import {UintUtils} from "../libraries/UintUtils.sol";
import {LibAppStorage} from "./LibAppStorage.sol";

/// @notice Access control library
library LibAccessControl {
    using AddressUtils for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using UintUtils for uint256;

    /// @notice Storage slot used to store data for this library
    bytes32 constant ACCESS_CONTROL_STORAGE_SLOT =
        bytes32(
            uint256(keccak256("ubiquity.contracts.access.control.storage")) - 1
        );

    /// @notice Structure to keep all role members with their admin role
    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    /// @notice Structure to keep all protocol roles
    struct Layout {
        mapping(bytes32 => RoleData) roles;
    }

    /// @notice Emitted when admin role of a role is updated
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    /// @notice Emitted when role is granted to account
    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /// @notice Emitted when role is revoked from account
    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    /// @notice Emitted when the pause is triggered by `account`
    event Paused(address account);

    /// @notice Emitted when the pause is lifted by `account`
    event Unpaused(address account);

    /**
     * @notice Returns struct used as a storage for this library
     * @return l Struct used as a storage
     */
    function accessControlStorage() internal pure returns (Layout storage l) {
        bytes32 slot = ACCESS_CONTROL_STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    /**
     * @notice Checks that a method can only be called by the provided role
     * @param role Role name
     */
    modifier onlyRole(bytes32 role) {
        checkRole(role);
        _;
    }

    /// @notice Returns true if the contract is paused and false otherwise
    function paused() internal view returns (bool) {
        return LibAppStorage.appStorage().paused;
    }

    /**
     * @notice Checks whether role is assigned to account
     * @param role Role to check
     * @param account Address to check
     * @return Whether role is assigned to account
     */
    function hasRole(
        bytes32 role,
        address account
    ) internal view returns (bool) {
        return accessControlStorage().roles[role].members.contains(account);
    }

    /**
     * @notice Reverts if sender does not have a given role
     * @param role Role to query
     */
    function checkRole(bytes32 role) internal view {
        checkRole(role, msg.sender);
    }

    /**
     * @notice Reverts if given account does not have a given role
     * @param role Role to query
     * @param account Address to query
     */
    function checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        account.toString(),
                        " is missing role ",
                        uint256(role).toHexString(32)
                    )
                )
            );
        }
    }

    /**
     * @notice Returns admin role for a given role
     * @param role Role to query
     * @return Admin role for a provided role
     */
    function getRoleAdmin(bytes32 role) internal view returns (bytes32) {
        return accessControlStorage().roles[role].adminRole;
    }

    /**
     * @notice Sets a new admin role for a provided role
     * @param role Role for which admin role should be set
     * @param adminRole Admin role to set
     */
    function setRoleAdmin(bytes32 role, bytes32 adminRole) internal {
        bytes32 previousAdminRole = getRoleAdmin(role);
        accessControlStorage().roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @notice Assigns role to a given account
     * @param role Role to assign
     * @param account Recipient of role assignment
     */
    function grantRole(bytes32 role, address account) internal {
        accessControlStorage().roles[role].members.add(account);
        emit RoleGranted(role, account, msg.sender);
    }

    /**
     * @notice Unassign role from a given account
     * @param role Role to unassign
     * @param account Address from which the provided role should be unassigned
     */
    function revokeRole(bytes32 role, address account) internal {
        accessControlStorage().roles[role].members.remove(account);
        emit RoleRevoked(role, account, msg.sender);
    }

    /**
     * @notice Renounces role
     * @param role Role to renounce
     */
    function renounceRole(bytes32 role) internal {
        revokeRole(role, msg.sender);
    }

    /// @notice Pauses the contract
    function pause() internal {
        LibAppStorage.appStorage().paused = true;
        emit Paused(msg.sender);
    }

    /// @notice Unpauses the contract
    function unpause() internal {
        LibAppStorage.appStorage().paused = false;
        emit Unpaused(msg.sender);
    }
}
