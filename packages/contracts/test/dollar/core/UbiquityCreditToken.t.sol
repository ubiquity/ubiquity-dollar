// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "../../../src/dollar/core/UbiquityCreditToken.sol";
import "../../helpers/LocalTestHelper.sol";

contract UbiquityCreditTokenTest is LocalTestHelper {
    UbiquityCreditToken ubiquityCreditToken;

    function setUp() public override {
        super.setUp();
        ubiquityCreditToken = creditToken;
    }

    function testRaiseCapital_ShouldMintTokens() public {
        assertEq(ubiquityCreditToken.balanceOf(treasuryAddress), 0);
        vm.prank(admin);
        ubiquityCreditToken.raiseCapital(1e18);
        assertEq(ubiquityCreditToken.balanceOf(treasuryAddress), 1e18);
    }

    function testSetManager_ShouldRevert_WhenNotAdmin() public {
        vm.prank(address(0x123abc));
        vm.expectRevert("ERC20Ubiquity: not admin");
        ubiquityCreditToken.setManager(address(0x123abc));
    }

    function testSetManager_ShouldSetManager() public {
        address newManager = address(0x123abc);
        vm.prank(admin);
        ubiquityCreditToken.setManager(newManager);
        require(ubiquityCreditToken.getManager() == newManager);
    }

    function testUUPS_ShouldUpgradeAndCall() external {
        UbiquityCreditTokenUpgraded newImpl = new UbiquityCreditTokenUpgraded();

        vm.startPrank(admin);
        bytes memory hasUpgradedCall = abi.encodeWithSignature("hasUpgraded()");
        // trying to directly call will fail and exit early so call it like this
        (bool success, ) = address(ubiquityCreditToken).call(hasUpgradedCall);
        assertEq(success, false, "should not have upgraded yet");
        require(success == false, "should not have upgraded yet");

        ubiquityCreditToken.upgradeTo(address(newImpl));

        // It will also fail unless cast so we'll use the same pattern as above
        (success, ) = address(ubiquityCreditToken).call(hasUpgradedCall);
        assertEq(success, true, "should have upgraded");
        require(success == true, "should have upgraded");

        vm.expectRevert();
        ubiquityCreditToken.initialize(address(diamond));
    }

    function testUUPS_ImplChanges() external {
        UbiquityCreditTokenUpgraded newImpl = new UbiquityCreditTokenUpgraded();

        address oldImpl = address(creditToken);
        address newImplAddr = address(newImpl);

        vm.prank(admin);
        ubiquityCreditToken.upgradeTo(newImplAddr);

        bytes memory getImplCall = abi.encodeWithSignature("getImpl()");

        (bool success, bytes memory data) = address(ubiquityCreditToken).call(
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

        UbiquityCreditTokenUpgraded newImpl = new UbiquityCreditTokenUpgraded();
        UbiquityCreditTokenUpgraded newImplT = new UbiquityCreditTokenUpgraded();

        vm.startPrank(admin);
        ubiquityCreditToken.upgradeTo(address(newImpl));

        bytes memory getVersionCall = abi.encodeWithSignature("getVersion()");

        (bool success, bytes memory data) = address(ubiquityCreditToken).call(
            getVersionCall
        );
        assertEq(success, true, "should have upgraded");
        uint8 version = abi.decode(data, (uint8));

        assertEq(
            version,
            expectedVersion,
            "should be the same version as only initialized once"
        );

        ubiquityCreditToken.upgradeTo(address(newImplT));

        (success, data) = address(ubiquityCreditToken).call(getVersionCall);
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
        UbiquityCreditTokenUpgraded newImpl = new UbiquityCreditTokenUpgraded();

        vm.startPrank(admin);
        vm.expectRevert();
        newImpl.initialize(address(diamond));

        vm.expectRevert();
        creditToken.initialize(address(diamond));

        vm.expectRevert();
        ubiquityCreditToken.initialize(address(diamond));

        ubiquityCreditToken.upgradeTo(address(newImpl));

        vm.expectRevert();
        ubiquityCreditToken.initialize(address(diamond));
    }

    function testUUPS_AdminAuth() external {
        UbiquityCreditTokenUpgraded newImpl = new UbiquityCreditTokenUpgraded();

        vm.expectRevert();
        ubiquityCreditToken.upgradeTo(address(newImpl));

        vm.prank(admin);
        ubiquityCreditToken.upgradeTo(address(newImpl));

        bytes memory hasUpgradedCall = abi.encodeWithSignature("hasUpgraded()");

        (bool success, bytes memory data) = address(ubiquityCreditToken).call(
            hasUpgradedCall
        );
        assertEq(success, true, "should have upgraded");

        bool hasUpgraded = abi.decode(data, (bool));
        assertEq(hasUpgraded, true, "should have upgraded");
        require(success == true, "should have upgraded");
    }
}

contract UbiquityCreditTokenUpgraded is UbiquityCreditToken {
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
