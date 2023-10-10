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
        accessControlFacet.grantRole(
            keccak256("GOVERNANCE_TOKEN_MANAGER_ROLE"),
            admin
        );
        vm.stopPrank();
    }

    function testSetManager_ShouldRevert_WhenNotAdmin() public {
        vm.prank(address(0x123abc));
        vm.expectRevert("ERC20Ubiquity: not admin");
        governanceToken.setManager(address(0x123abc));
    }

    function testSetManager_ShouldSetManager() public {
        address newManager = address(0x123abc);
        vm.prank(admin);
        governanceToken.setManager(newManager);
        require(governanceToken.getManager() == newManager);
    }

    function testUUPS_ShouldUpgradeAndCall() external {
        UbiquityGovernanceTokenUpgraded newImpl = new UbiquityGovernanceTokenUpgraded();

        vm.startPrank(admin);
        bytes memory hasUpgradedCall = abi.encodeWithSignature("hasUpgraded()");

        // trying to directly call will fail and exit early so call it like this
        (bool success, ) = address(governanceToken).call(hasUpgradedCall);
        assertEq(success, false, "should not have upgraded yet");
        require(success == false, "should not have upgraded yet");

        governanceToken.upgradeTo(address(newImpl));

        // It will also fail unless cast so we'll use the same pattern as above
        (success, ) = address(governanceToken).call(hasUpgradedCall);
        assertEq(success, true, "should have upgraded");
        require(success == true, "should have upgraded");

        vm.expectRevert();
        governanceToken.initialize(address(diamond));

        vm.stopPrank();
    }

    function testUUPS_ImplChanges() external {
        UbiquityGovernanceTokenUpgraded newImpl = new UbiquityGovernanceTokenUpgraded();

        address oldImpl = address(governanceToken);
        address newImplAddr = address(newImpl);

        vm.prank(admin);
        governanceToken.upgradeTo(newImplAddr);

        bytes memory getImplCall = abi.encodeWithSignature("getImpl()");

        (bool success, bytes memory data) = address(governanceToken).call(
            getImplCall
        );
        assertEq(success, true, "should have upgraded");

        address newAddrViaNewFunc = abi.decode(data, (address));

        assertEq(
            newAddrViaNewFunc,
            newImplAddr,
            "should be the new implementation"
        );
        assertTrue(
            newAddrViaNewFunc != oldImpl,
            "should not be the old implementation"
        );
    }

    function testUUPS_InitializedVersion() external {
        uint expectedVersion = 1;
        uint baseExpectedVersion = 255;

        UbiquityGovernanceTokenUpgraded newImpl = new UbiquityGovernanceTokenUpgraded();
        UbiquityGovernanceTokenUpgraded newImplT = new UbiquityGovernanceTokenUpgraded();

        vm.startPrank(admin);
        governanceToken.upgradeTo(address(newImpl));
        // It will also fail unless cast so we'll use the same pattern as above
        (bool success, bytes memory data) = address(governanceToken).call(
            abi.encodeWithSignature("getVersion()")
        );
        assertEq(success, true, "should have upgraded");
        uint8 version = abi.decode(data, (uint8));

        assertEq(
            version,
            expectedVersion,
            "should be the same version as only initialized once"
        );

        governanceToken.upgradeTo(address(newImplT));

        (success, data) = address(governanceToken).call(
            abi.encodeWithSignature("getVersion()")
        );
        assertEq(success, true, "should have upgraded");
        version = abi.decode(data, (uint8));

        assertEq(
            version,
            expectedVersion,
            "should be the same version as only initialized once"
        );

        (success, data) = address(newImpl).call(
            abi.encodeWithSignature("getVersion()")
        );
        assertEq(success, true, "should succeed");
        version = abi.decode(data, (uint8));

        assertEq(
            version,
            baseExpectedVersion,
            "should be maxed as initializers are disabled."
        );
    }

    function testUUPS_initialization() external {
        UbiquityGovernanceTokenUpgraded newImpl = new UbiquityGovernanceTokenUpgraded();

        vm.startPrank(admin);
        vm.expectRevert();
        newImpl.initialize(address(diamond));

        vm.expectRevert();
        governanceToken.initialize(address(diamond));

        governanceToken.upgradeTo(address(newImpl));

        vm.expectRevert();
        governanceToken.initialize(address(diamond));
    }

    function testUUPS_AdminAuth() external {
        UbiquityGovernanceTokenUpgraded newImpl = new UbiquityGovernanceTokenUpgraded();

        vm.expectRevert();
        governanceToken.upgradeTo(address(newImpl));

        vm.prank(admin);
        governanceToken.upgradeTo(address(newImpl));

        bytes memory hasUpgradedCall = abi.encodeWithSignature("hasUpgraded()");

        (bool success, bytes memory data) = address(governanceToken).call(
            hasUpgradedCall
        );
        bool hasUpgraded = abi.decode(data, (bool));

        assertEq(hasUpgraded, true, "should have upgraded");
        assertEq(success, true, "should have upgraded");
        require(success == true, "should have upgraded");
    }
}

contract UbiquityGovernanceTokenUpgraded is UbiquityGovernanceToken {
    function hasUpgraded() public pure returns (bool) {
        return true;
    }

    function getVersion() public view returns (uint8) {
        return super._getInitializedVersion();
    }

    function getImpl() public view returns (address) {
        return super._getImplementation();
    }
}
