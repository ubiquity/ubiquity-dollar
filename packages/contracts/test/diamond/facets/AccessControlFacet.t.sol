// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {AccessControlFacet} from "../../../src/diamond/facets/AccessControlFacet.sol";
import "../../../src/diamond/libraries/Constants.sol";
import "../DiamondTestSetup.sol";
import {AddressUtils} from "../../../src/diamond/libraries/AddressUtils.sol";

import {UintUtils} from "../../../src/diamond/libraries/UintUtils.sol";

contract AccessControlFacetTest is DiamondSetup {
    using AddressUtils for address;
    using UintUtils for uint256;
    address mock_sender = address(0x111);
    address mock_recipient = address(0x222);
    address mock_operator = address(0x333);

    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    // test grantRole function should work only for admin
    function testgrantRole_ShouldWork() public {
        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit RoleGranted(GOVERNANCE_TOKEN_BURNER_ROLE, mock_recipient, admin);
        IAccessCtrl.grantRole(GOVERNANCE_TOKEN_BURNER_ROLE, mock_recipient);
    }

    // test grantRole function should revert if sender is not admin
    function testgrantRole_ShouldRevertWhenNotAdmin() public {
        vm.prank(mock_sender);

        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                mock_sender.toString(),
                " is missing role ",
                uint256(DEFAULT_ADMIN_ROLE).toHexString(32)
            )
        );
        IAccessCtrl.grantRole(GOVERNANCE_TOKEN_BURNER_ROLE, mock_recipient);
    }

    // test revokeRole function should work only for admin
    function testRevokeRole_ShouldWork() public {
        vm.prank(admin);
        emit RoleGranted(GOVERNANCE_TOKEN_BURNER_ROLE, mock_recipient, admin);
        IAccessCtrl.grantRole(GOVERNANCE_TOKEN_BURNER_ROLE, mock_recipient);

        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit RoleRevoked(GOVERNANCE_TOKEN_BURNER_ROLE, mock_recipient, admin);
        IAccessCtrl.revokeRole(GOVERNANCE_TOKEN_BURNER_ROLE, mock_recipient);
    }

    // test revokeRole function should revert if sender is not admin
    function testRevokeRole_ShouldRevertWhenNotAdmin() public {
        vm.prank(mock_sender);

        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                mock_sender.toString(),
                " is missing role ",
                uint256(DEFAULT_ADMIN_ROLE).toHexString(32)
            )
        );
        IAccessCtrl.revokeRole(GOVERNANCE_TOKEN_BURNER_ROLE, mock_recipient);
    }

    // test renounceRole function should work for grantee
    function testRenounceRole_ShouldWork() public {
        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit RoleGranted(GOVERNANCE_TOKEN_BURNER_ROLE, mock_recipient, admin);
        IAccessCtrl.grantRole(GOVERNANCE_TOKEN_BURNER_ROLE, mock_recipient);

        vm.prank(mock_recipient);
        vm.expectEmit(true, true, true, true);
        emit RoleRevoked(
            GOVERNANCE_TOKEN_BURNER_ROLE,
            mock_recipient,
            mock_recipient
        );
        IAccessCtrl.renounceRole(GOVERNANCE_TOKEN_BURNER_ROLE);
    }
}
