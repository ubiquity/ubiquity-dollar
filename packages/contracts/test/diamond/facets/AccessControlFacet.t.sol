// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AccessControlFacet} from "../../../src/dollar/facets/AccessControlFacet.sol";
import "../../../src/dollar/libraries/Constants.sol";
import "../DiamondTestSetup.sol";
import {AddressUtils} from "../../../src/dollar/libraries/AddressUtils.sol";

import {UintUtils} from "../../../src/dollar/libraries/UintUtils.sol";

contract AccessControlFacetTest is DiamondTestSetup {
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
    function testGrantRole_ShouldWork() public {
        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit RoleGranted(GOVERNANCE_TOKEN_BURNER_ROLE, mock_recipient, admin);
        accessControlFacet.grantRole(
            GOVERNANCE_TOKEN_BURNER_ROLE,
            mock_recipient
        );
    }

    // test grantRole function should revert if sender is not admin
    function testGrantRole_ShouldRevertWhenNotAdmin() public {
        vm.prank(mock_sender);

        vm.expectRevert(
            abi.encodePacked(
                "AccessControl: account ",
                mock_sender.toString(),
                " is missing role ",
                uint256(DEFAULT_ADMIN_ROLE).toHexString(32)
            )
        );
        accessControlFacet.grantRole(
            GOVERNANCE_TOKEN_BURNER_ROLE,
            mock_recipient
        );
    }

    // test revokeRole function should work only for admin
    function testRevokeRole_ShouldWork() public {
        vm.prank(admin);
        emit RoleGranted(GOVERNANCE_TOKEN_BURNER_ROLE, mock_recipient, admin);
        accessControlFacet.grantRole(
            GOVERNANCE_TOKEN_BURNER_ROLE,
            mock_recipient
        );

        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit RoleRevoked(GOVERNANCE_TOKEN_BURNER_ROLE, mock_recipient, admin);
        accessControlFacet.revokeRole(
            GOVERNANCE_TOKEN_BURNER_ROLE,
            mock_recipient
        );
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
        accessControlFacet.revokeRole(
            GOVERNANCE_TOKEN_BURNER_ROLE,
            mock_recipient
        );
    }

    // test renounceRole function should work for grantee
    function testRenounceRole_ShouldWork() public {
        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit RoleGranted(GOVERNANCE_TOKEN_BURNER_ROLE, mock_recipient, admin);
        accessControlFacet.grantRole(
            GOVERNANCE_TOKEN_BURNER_ROLE,
            mock_recipient
        );

        vm.prank(mock_recipient);
        vm.expectEmit(true, true, true, true);
        emit RoleRevoked(
            GOVERNANCE_TOKEN_BURNER_ROLE,
            mock_recipient,
            mock_recipient
        );
        accessControlFacet.renounceRole(GOVERNANCE_TOKEN_BURNER_ROLE);
    }
}
