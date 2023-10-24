// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {UbiquityDollarToken} from "../../../src/dollar/core/UbiquityDollarToken.sol";
import {IIncentive} from "../../../src/dollar/interfaces/IIncentive.sol";

import "../../helpers/LocalTestHelper.sol";

contract Incentive is IIncentive {
    function incentivize(
        address sender,
        address recipient,
        address operator,
        uint256 amount
    ) public {}
}

contract UbiquityDollarTokenTest is LocalTestHelper {
    address incentive_addr;
    address dollar_addr;
    address dollar_manager_address;

    address mock_sender = address(0x111);
    address mock_recipient = address(0x222);
    address mock_operator = address(0x333);

    event IncentiveContractUpdate(
        address indexed _incentivized,
        address indexed _incentiveContract
    );

    function setUp() public override {
        incentive_addr = address(new Incentive());
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

    function testSetIncentiveContract_ShouldRevert_IfNotAdmin() public {
        vm.prank(mock_sender);
        vm.expectRevert("Dollar: must have admin role");
        dollarToken.setIncentiveContract(mock_sender, incentive_addr);

        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit IncentiveContractUpdate(mock_sender, incentive_addr);
        dollarToken.setIncentiveContract(mock_sender, incentive_addr);
    }

    function testTransfer_ShouldCallIncentivize_IfValidTransfer() public {
        address userA = address(0x100001);
        address userB = address(0x100001);
        vm.startPrank(admin);
        dollarToken.mint(userA, 100);
        dollarToken.mint(userB, 100);
        dollarToken.mint(mock_sender, 100);

        dollarToken.setIncentiveContract(mock_sender, incentive_addr);
        dollarToken.setIncentiveContract(mock_recipient, incentive_addr);
        dollarToken.setIncentiveContract(mock_operator, incentive_addr);
        dollarToken.setIncentiveContract(address(0), incentive_addr);
        dollarToken.setIncentiveContract(dollar_addr, incentive_addr);
        vm.stopPrank();

        vm.prank(mock_sender);
        vm.expectCall(
            incentive_addr,
            abi.encodeWithSelector(
                Incentive.incentivize.selector,
                mock_sender,
                userB,
                mock_sender,
                1
            )
        );
        dollarToken.transfer(userB, 1);

        vm.prank(userA);
        vm.expectCall(
            incentive_addr,
            abi.encodeWithSelector(
                Incentive.incentivize.selector,
                userA,
                mock_recipient,
                userA,
                1
            )
        );
        dollarToken.transfer(mock_recipient, 1);
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
