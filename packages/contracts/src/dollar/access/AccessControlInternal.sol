// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {AddressUtils} from "../libraries/AddressUtils.sol";
import {UintUtils} from "../libraries/UintUtils.sol";
import {LibAccessControl} from "../libraries/LibAccessControl.sol";

/**
 * @notice Role-based access control system
 * @dev Derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 * @dev https://github.com/solidstate-network/solidstate-solidity/blob/master/contracts/access/access_control/AccessControlInternal.sol
 */
abstract contract AccessControlInternal {
    using AddressUtils for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using UintUtils for uint256;

    /**
     * @notice Checks that a method can only be called by the provided role
     * @param role Role name
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @notice Checks whether role is assigned to account
     * @param role Role to check
     * @param account Account address to check
     * @return Whether role is assigned to account
     */
    function _hasRole(
        bytes32 role,
        address account
    ) internal view virtual returns (bool) {
        return
            LibAccessControl
                .accessControlStorage()
                .roles[role]
                .members
                .contains(account);
    }

    /**
     * @notice Reverts if sender does not have a given role
     * @param role Role to query
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, msg.sender);
    }

    /**
     * @notice Reverts if given account does not have a given role
     * @param role Role to query
     * @param account Address to query
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!_hasRole(role, account)) {
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
     * @return Admin role for the provided role
     */
    function _getRoleAdmin(
        bytes32 role
    ) internal view virtual returns (bytes32) {
        return LibAccessControl.accessControlStorage().roles[role].adminRole;
    }

    /**
     * @notice Assigns role to a given account
     * @param role Role to assign
     * @param account Recipient of role assignment
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        LibAccessControl.accessControlStorage().roles[role].members.add(
            account
        );
        emit LibAccessControl.RoleGranted(role, account, msg.sender);
    }

    /**
     * @notice Unassigns role from given account
     * @param role Role to unassign
     * @param account Account to revoke a role from
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        LibAccessControl.accessControlStorage().roles[role].members.remove(
            account
        );
        emit LibAccessControl.RoleRevoked(role, account, msg.sender);
    }

    /**
     * @notice Renounces role
     * @param role Role to renounce
     */
    function _renounceRole(bytes32 role) internal virtual {
        _revokeRole(role, msg.sender);
    }
}
