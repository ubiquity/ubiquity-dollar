// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {AccessControlFacet} from "../../../src/dollar/facets/AccessControlFacet.sol";
import "../../../src/dollar/libraries/Constants.sol";
import "../DiamondTestSetup.sol";
import {MockERC20} from "../../../src/dollar/mocks/MockERC20.sol";

contract CollectableDustFacetTest is DiamondTestSetup {
    address mock_sender = address(0x111);
    address mock_recipient = address(0x222);
    address mock_operator = address(0x333);
    address stakingManager = address(0x414);
    MockERC20 mockToken;

    event DustSent(address _to, address token, uint256 amount);
    event ProtocolTokenAdded(address _token);
    event ProtocolTokenRemoved(address _token);

    function setUp() public virtual override {
        super.setUp();

        vm.startPrank(admin);

        accessControlFacet.grantRole(STAKING_MANAGER_ROLE, stakingManager);

        // deploy mock token
        mockToken = new MockERC20("Mock", "MCK", 18);

        // mint MCK
        mockToken.mint(address(diamond), 100);
        vm.stopPrank();
    }

    // test sendDust function should revert when token is part of the protocol
    function testSendDust_ShouldRevertWhenPartOfTheProtocol() public {
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, true);
        emit ProtocolTokenAdded(address(diamond));
        collectableDustFacet.addProtocolToken(address(diamond));
        // mint dollar

        dollarToken.mint(address(diamond), 100);
        vm.stopPrank();
        vm.prank(stakingManager);
        vm.expectRevert("collectable-dust::token-is-part-of-the-protocol");
        collectableDustFacet.sendDust(mock_recipient, address(diamond), 100);
    }

    // test sendDust function should work only for staking manager
    function testSendDust_ShouldWork() public {
        assertEq(mockToken.balanceOf(address(diamond)), 100);
        vm.prank(stakingManager);
        vm.expectEmit(true, true, true, true);
        emit DustSent(mock_recipient, address(mockToken), 100);
        collectableDustFacet.sendDust(mock_recipient, address(mockToken), 100);
        assertEq(mockToken.balanceOf(mock_recipient), 100);
    }

    // test sendDust function should work when token is no longer part of the protocol
    function testSendDust_ShouldWorkWhenNotPartOfTheProtocol() public {
        vm.startPrank(admin);

        collectableDustFacet.addProtocolToken(address(diamond));
        vm.expectEmit(true, true, true, true);
        emit ProtocolTokenRemoved(address(diamond));
        collectableDustFacet.removeProtocolToken(address(diamond));
        // mint dollar

        dollarToken.mint(address(diamond), 100);
        vm.stopPrank();
        assertEq(dollarToken.balanceOf(address(diamond)), 100);
        vm.prank(stakingManager);

        collectableDustFacet.sendDust(
            mock_recipient,
            address(dollarToken),
            100
        );
        assertEq(dollarToken.balanceOf(address(diamond)), 0);
        assertEq(dollarToken.balanceOf(address(mock_recipient)), 100);
    }
}
