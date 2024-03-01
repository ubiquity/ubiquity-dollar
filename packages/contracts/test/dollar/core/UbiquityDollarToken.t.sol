// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {UbiquityDollarToken} from "../../../src/dollar/core/UbiquityDollarToken.sol";

import "../../helpers/LocalTestHelper.sol";

contract UbiquityDollarTokenTest is LocalTestHelper {
    address dollar_addr;
    address dollar_manager_address;

    address mock_sender = address(0x111);
    address mock_recipient = address(0x222);
    address mock_operator = address(0x333);

    function setUp() public override {
        super.setUp();
        vm.startPrank(admin);
        dollar_addr = address(dollarToken);

        accessControlFacet.grantRole(
            keccak256("GOVERNANCE_TOKEN_MANAGER_ROLE"),
            admin
        );
        vm.stopPrank();
    }

    function testSetManager_ShouldRevert_WhenNotAdmin() public {
        vm.prank(address(0x123abc));
        vm.expectRevert("ERC20Ubiquity: not admin");
        dollarToken.setManager(address(0x123abc));
    }

    function testSetManager_ShouldSetManager() public {
        address newDiamond = address(0x123abc);
        vm.prank(admin);
        dollarToken.setManager(newDiamond);
        require(dollarToken.getManager() == newDiamond);
    }

    function testUUPS_ShouldUpgradeAndCall() external {
        UbiquityDollarTokenUpgraded newImpl = new UbiquityDollarTokenUpgraded();

        vm.startPrank(admin);
        bytes memory hasUpgradedCall = abi.encodeWithSignature("hasUpgraded()");

        // trying to directly call will fail and exit early so call it like this
        (bool success, ) = address(dollarToken).call(hasUpgradedCall);
        assertEq(success, false, "should not have upgraded yet");
        require(success == false, "should not have upgraded yet");

        dollarToken.upgradeTo(address(newImpl));

        // It will also fail unless cast so we'll use the same pattern as above
        (success, ) = address(dollarToken).call(hasUpgradedCall);
        assertEq(success, true, "should have upgraded");
        require(success == true, "should have upgraded");

        vm.expectRevert();
        dollarToken.initialize(address(diamond));
    }

    function testUUPS_ImplChanges() external {
        UbiquityDollarTokenUpgraded newImpl = new UbiquityDollarTokenUpgraded();

        address oldImpl = address(dollarToken);
        address newImplAddr = address(newImpl);

        vm.prank(admin);
        dollarToken.upgradeTo(newImplAddr);

        bytes memory getImplCall = abi.encodeWithSignature("getImpl()");

        (bool success, bytes memory data) = address(dollarToken).call(
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

        UbiquityDollarTokenUpgraded newImpl = new UbiquityDollarTokenUpgraded();
        UbiquityDollarTokenUpgraded newImplT = new UbiquityDollarTokenUpgraded();

        vm.startPrank(admin);
        dollarToken.upgradeTo(address(newImpl));
        bytes memory getVersionCall = abi.encodeWithSignature("getVersion()");

        (bool success, bytes memory data) = address(dollarToken).call(
            getVersionCall
        );
        assertEq(success, true, "should have upgraded");
        uint8 version = abi.decode(data, (uint8));

        assertEq(
            version,
            expectedVersion,
            "should be the same version as only initialized once"
        );

        dollarToken.upgradeTo(address(newImplT));

        (success, data) = address(dollarToken).call(getVersionCall);
        assertEq(success, true, "should have upgraded");
        version = abi.decode(data, (uint8));

        assertEq(
            version,
            expectedVersion,
            "should be the same version as only initialized once"
        );

        (success, data) = address(newImpl).call(getVersionCall);
        assertEq(success, true, "should succeed");
        version = abi.decode(data, (uint8));

        assertEq(
            version,
            baseExpectedVersion,
            "should be maxed as initializers are disabled."
        );
    }

    function testUUPS_initialization() external {
        UbiquityDollarTokenUpgraded newImpl = new UbiquityDollarTokenUpgraded();

        vm.startPrank(admin);
        vm.expectRevert();
        newImpl.initialize(address(diamond));

        vm.expectRevert();
        dollarToken.initialize(address(diamond));

        dollarToken.upgradeTo(address(newImpl));

        vm.expectRevert();
        dollarToken.initialize(address(diamond));
    }

    function testUUPS_AdminAuth() external {
        UbiquityDollarTokenUpgraded newImpl = new UbiquityDollarTokenUpgraded();

        vm.expectRevert();
        dollarToken.upgradeTo(address(newImpl));

        vm.prank(admin);
        dollarToken.upgradeTo(address(newImpl));

        bytes memory hasUpgradedCall = abi.encodeWithSignature("hasUpgraded()");
        (bool success, bytes memory data) = address(dollarToken).call(
            hasUpgradedCall
        );
        bool hasUpgraded = abi.decode(data, (bool));

        assertEq(hasUpgraded, true, "should have upgraded");
        assertEq(success, true, "should have upgraded");
        require(success == true, "should have upgraded");
    }
}

contract UbiquityDollarTokenUpgraded is UbiquityDollarToken {
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
