// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {UbiquityDollarToken} from
    "../../../src/dollar/core/UbiquityDollarToken.sol";
import {MockIncentive} from "../../../src/dollar/mocks/MockIncentive.sol";

import "../../helpers/LocalTestHelper.sol";

contract UbiquityDollarTokenTest is LocalTestHelper {
    address incentive_addr;
    address dollar_addr;
    address dollar_manager_address;

    address mock_sender = address(0x111);
    address mock_recipient = address(0x222);
    address mock_operator = address(0x333);

    event IncentiveContractUpdate(
        address indexed _incentivized, address indexed _incentiveContract
    );

    function setUp() public {
        incentive_addr = address(new MockIncentive());
        dollar_manager_address = helpers_deployUbiquityDollarManager();
        vm.startPrank(admin);
        dollar_addr = address(new UbiquityDollarToken(dollar_manager_address));
        UbiquityDollarManager(dollar_manager_address).grantRole(
            keccak256("GOV_TOKEN_MANAGER_ROLE"), admin
        );
        vm.stopPrank();
    }

    function test_setIncentiveContract() public {
        vm.prank(mock_sender);
        vm.expectRevert("Dollar: must have admin role");
        UbiquityDollarToken(dollar_addr).setIncentiveContract(
            mock_sender, incentive_addr
        );

        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit IncentiveContractUpdate(mock_sender, incentive_addr);
        UbiquityDollarToken(dollar_addr).setIncentiveContract(
            mock_sender, incentive_addr
        );
    }

    function test_transferIncentive() public {
        address userA = address(0x100001);
        address userB = address(0x100001);
        vm.startPrank(admin);
        UbiquityDollarToken(dollar_addr).mint(userA, 100);
        UbiquityDollarToken(dollar_addr).mint(userB, 100);
        UbiquityDollarToken(dollar_addr).mint(mock_sender, 100);

        UbiquityDollarToken(dollar_addr).setIncentiveContract(
            mock_sender, incentive_addr
        );
        UbiquityDollarToken(dollar_addr).setIncentiveContract(
            mock_recipient, incentive_addr
        );
        UbiquityDollarToken(dollar_addr).setIncentiveContract(
            mock_operator, incentive_addr
        );
        UbiquityDollarToken(dollar_addr).setIncentiveContract(
            address(0), incentive_addr
        );
        UbiquityDollarToken(dollar_addr).setIncentiveContract(
            dollar_addr, incentive_addr
        );
        vm.stopPrank();

        vm.prank(mock_sender);
        vm.expectCall(
            incentive_addr,
            abi.encodeWithSelector(
                MockIncentive.incentivize.selector,
                mock_sender,
                userB,
                mock_sender,
                1
            )
        );
        UbiquityDollarToken(dollar_addr).transfer(userB, 1);

        vm.prank(userA);
        vm.expectCall(
            incentive_addr,
            abi.encodeWithSelector(
                MockIncentive.incentivize.selector,
                userA,
                mock_recipient,
                userA,
                1
            )
        );
        UbiquityDollarToken(dollar_addr).transfer(mock_recipient, 1);
    }
}
