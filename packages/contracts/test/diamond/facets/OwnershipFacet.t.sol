// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import {OwnershipFacet} from "../../../src/dollar/facets/OwnershipFacet.sol";
import "../../../src/dollar/libraries/Constants.sol";
import "../DiamondTestSetup.sol";
import {AddressUtils} from "../../../src/dollar/libraries/AddressUtils.sol";

import {UintUtils} from "../../../src/dollar/libraries/UintUtils.sol";

contract OwnershipFacetTest is DiamondSetup {
    using AddressUtils for address;
    using UintUtils for uint256;
    address mock_sender = address(0x111);
    address mock_recipient = address(0x222);
    address mock_operator = address(0x333);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    // test OwnershipFacet transferOwnership should revert if sender is not owner
    function testTransferOwnership_ShouldRevertWhenNotOwner() public {
        assertEq(IOwnershipFacet.owner(), owner);
        vm.prank(mock_sender);
        vm.expectRevert(abi.encodePacked("LibDiamond: Must be contract owner"));
        IOwnershipFacet.transferOwnership(mock_recipient);
        assertEq(IOwnershipFacet.owner(), owner);
    }

    // test OwnershipFacet transferOwnership should revert if new owner is zero address
    function testTransferOwnership_ShouldRevertWhenNewOwnerIsZeroAddress()
        public
    {
        assertEq(IOwnershipFacet.owner(), owner);
        vm.prank(owner);
        vm.expectRevert(
            abi.encodePacked(
                "OwnershipFacet: New owner cannot be the zero address"
            )
        );
        IOwnershipFacet.transferOwnership(address(0));
        assertEq(IOwnershipFacet.owner(), owner);
    }

    // test OwnershipFacet transferOwnership should work if new owner is not contract
    function testTransferOwnership_ShouldWorkWhenNewOwnerIsNotContract()
        public
    {
        vm.prank(owner);
        vm.expectEmit(true, true, true, true);
        emit OwnershipTransferred(owner, mock_recipient);
        IOwnershipFacet.transferOwnership(mock_recipient);
        assertEq(IOwnershipFacet.owner(), mock_recipient);
    }
}
