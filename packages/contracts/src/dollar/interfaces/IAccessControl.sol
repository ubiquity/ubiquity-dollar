// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/// @notice Access contol interface
interface IAccessControl {
    /**
     * @notice Checks whether role is assigned to account
     * @param role Role to check
     * @param account Address to check
     * @return Whether role is assigned to account
     */
    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool);

    /**
     * @notice Returns admin role for a given role
     * @param role Role to query
     * @return Admin role for a provided role
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @notice Assigns role to a given account
     * @param role Role to assign
     * @param account Recipient address of role assignment
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @notice Unassign role from a given account
     * @param role Role to unassign
     * @param account Address from which the provided role should be unassigned
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @notice Renounce role
     * @param role Role to renounce
     */
    function renounceRole(bytes32 role) external;
}
