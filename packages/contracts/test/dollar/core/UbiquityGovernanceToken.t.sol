// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {UbiquityGovernanceToken} from "../../../src/dollar/core/UbiquityGovernanceToken.sol";

import "../../helpers/LocalTestHelper.sol";

contract UbiquityGovernanceTokenTest is LocalTestHelper {
    address mock_sender = address(0x111);
    address mock_recipient = address(0x222);
    address mock_operator = address(0x333);

    function setUp() public override {
        super.setUp();
        vm.startPrank(admin);
        IAccessControl.grantRole(
            keccak256("GOVERNANCE_TOKEN_MANAGER_ROLE"),
            admin
        );
        vm.stopPrank();
    }

    function testSetManager_ShouldRevert_WhenNotAdmin() public {
        vm.prank(address(0x123abc));
        vm.expectRevert("ERC20Ubiquity: not admin");
        IGovToken.setManager(address(0x123abc));
    }

    function testSetManager_ShouldSetManager() public {
        address newManager = address(0x123abc);
        vm.prank(admin);
        IGovToken.setManager(newManager);
        require(IGovToken.getManager() == newManager);
    }
}
