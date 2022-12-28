// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {UbiquityDollarTokenFacet} from "../../../src/diamond/facets/UbiquityDollarTokenFacet.sol";

import "../DiamondTestSetup.sol";

contract UbiquityDollarTokenFacetTest is DiamondSetup {
    address mock_sender = address(0x111);
    address mock_recipient = address(0x222);
    address mock_operator = address(0x333);

    event IncentiveContractUpdate(
        address indexed _incentivized,
        address indexed _incentiveContract
    );

    function test_setIncentiveContract() public {
        vm.prank(mock_sender);
        vm.expectRevert("Dollar: must have admin role");
        UbiquityDollarTokenFacet(address(IUbiquityDollarToken))
            .setIncentiveContract(mock_sender, incentive_addr);

        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit IncentiveContractUpdate(mock_sender, incentive_addr);
        UbiquityDollarTokenFacet(address(IUbiquityDollarToken))
            .setIncentiveContract(mock_sender, incentive_addr);
    }

    function test_transferIncentive() public {
        address userA = address(0x100001);
        address userB = address(0x100001);
        vm.startPrank(admin);
        UbiquityDollarTokenFacet(address(IUbiquityDollarToken)).mint(
            userA,
            100
        );
        UbiquityDollarTokenFacet(address(IUbiquityDollarToken)).mint(
            userB,
            100
        );
        UbiquityDollarTokenFacet(address(IUbiquityDollarToken)).mint(
            mock_sender,
            100
        );

        UbiquityDollarTokenFacet(address(IUbiquityDollarToken))
            .setIncentiveContract(mock_sender, incentive_addr);
        UbiquityDollarTokenFacet(address(IUbiquityDollarToken))
            .setIncentiveContract(mock_recipient, incentive_addr);
        UbiquityDollarTokenFacet(address(IUbiquityDollarToken))
            .setIncentiveContract(mock_operator, incentive_addr);
        UbiquityDollarTokenFacet(address(IUbiquityDollarToken))
            .setIncentiveContract(address(0), incentive_addr);
        UbiquityDollarTokenFacet(address(IUbiquityDollarToken))
            .setIncentiveContract(
                address(IUbiquityDollarToken),
                incentive_addr
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
        UbiquityDollarTokenFacet(address(IUbiquityDollarToken)).transfer(
            userB,
            1
        );

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
        UbiquityDollarTokenFacet(address(IUbiquityDollarToken)).transfer(
            mock_recipient,
            1
        );
    }
}
