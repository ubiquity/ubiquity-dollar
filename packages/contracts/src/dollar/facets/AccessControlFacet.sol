// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IAccessControl} from "../interfaces/IAccessControl.sol";
import {AccessControlInternal} from "../access/AccessControlInternal.sol";
import {LibAccessControl} from "../libraries/LibAccessControl.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

/**
 * @notice Role-based access control facet
 * @dev Derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 * @dev https://github.com/solidstate-network/solidstate-solidity/blob/master/contracts/access/access_control/AccessControl.sol
 */
contract AccessControlFacet is
    Modifiers,
    IAccessControl,
    AccessControlInternal
{
    /// @inheritdoc IAccessControl
    function grantRole(
        bytes32 role,
        address account
    ) external onlyRole(_getRoleAdmin(role)) {
        return _grantRole(role, account);
    }

    /// @inheritdoc IAccessControl
    function hasRole(
        bytes32 role,
        address account
    ) external view returns (bool) {
        return _hasRole(role, account);
    }

    /// @inheritdoc IAccessControl
    function getRoleAdmin(bytes32 role) external view returns (bytes32) {
        return _getRoleAdmin(role);
    }

    /// @inheritdoc IAccessControl
    function revokeRole(
        bytes32 role,
        address account
    ) external onlyRole(_getRoleAdmin(role)) {
        return _revokeRole(role, account);
    }

    /// @inheritdoc IAccessControl
    function renounceRole(bytes32 role) external {
        return _renounceRole(role);
    }

    /// @notice Returns true if the contract is paused and false otherwise
    function paused() public view returns (bool) {
        return LibAccessControl.paused();
    }

    /// @notice Pauses the contract
    function pause() external whenNotPaused onlyAdmin {
        LibAccessControl.pause();
    }

    /// @notice Unpauses the contract
    function unpause() external whenPaused onlyAdmin {
        LibAccessControl.unpause();
    }
}
