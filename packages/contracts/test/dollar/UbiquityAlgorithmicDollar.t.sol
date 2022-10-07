// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {UbiquityAlgorithmicDollar} from "../../src/dollar/UbiquityAlgorithmicDollar.sol";
import {MockIncentive} from "../../src/dollar/mocks/MockIncentive.sol";

import "../helpers/LocalTestHelper.sol";

contract UbiquityAlgorithmicDollarTest is LocalTestHelper {
    address incentive_addr;
    address uad_addr;
    address uad_manager_address;

    address mock_sender = address(0x111);
    address mock_recipient = address(0x222);
    address mock_operator = address(0x333);

    event IncentiveContractUpdate(address indexed _incentivized, address indexed _incentiveContract);

    function setUp() public {
        incentive_addr = address(new MockIncentive());
        uad_manager_address = helpers_deployUbiquityAlgorithmicDollarManager();
        vm.startPrank(admin);
        uad_addr = address(new UbiquityAlgorithmicDollar(uad_manager_address));
        UbiquityAlgorithmicDollarManager(uad_manager_address).grantRole(keccak256("UBQ_TOKEN_MANAGER_ROLE"), admin);
        vm.stopPrank();
    }

    function test_setIncentiveContract() public {
        vm.prank(mock_sender);
        vm.expectRevert("Dollar: must have admin role");
        UbiquityAlgorithmicDollar(uad_addr).setIncentiveContract(mock_sender, incentive_addr);

        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit IncentiveContractUpdate(mock_sender, incentive_addr);
        UbiquityAlgorithmicDollar(uad_addr).setIncentiveContract(mock_sender, incentive_addr);
    }

    function test_transferIncentive() public {
        address userA = address(0x100001);
        address userB = address(0x100001);
        vm.startPrank(admin);
        UbiquityAlgorithmicDollar(uad_addr).mint(userA, 100);
        UbiquityAlgorithmicDollar(uad_addr).mint(userB, 100);
        UbiquityAlgorithmicDollar(uad_addr).mint(mock_sender, 100);

        UbiquityAlgorithmicDollar(uad_addr).setIncentiveContract(mock_sender, incentive_addr);
        UbiquityAlgorithmicDollar(uad_addr).setIncentiveContract(mock_recipient, incentive_addr);
        UbiquityAlgorithmicDollar(uad_addr).setIncentiveContract(mock_operator, incentive_addr);
        UbiquityAlgorithmicDollar(uad_addr).setIncentiveContract(address(0), incentive_addr);
        UbiquityAlgorithmicDollar(uad_addr).setIncentiveContract(uad_addr, incentive_addr);
        vm.stopPrank();

        vm.prank(mock_sender);
        vm.expectCall(incentive_addr, abi.encodeWithSelector(MockIncentive.incentivize.selector, mock_sender, userB, mock_sender, 1));
        UbiquityAlgorithmicDollar(uad_addr).transfer(userB, 1);

        vm.prank(userA);
        vm.expectCall(incentive_addr, abi.encodeWithSelector(MockIncentive.incentivize.selector, userA, mock_recipient, userA, 1));
        UbiquityAlgorithmicDollar(uad_addr).transfer(mock_recipient, 1);

    }
}