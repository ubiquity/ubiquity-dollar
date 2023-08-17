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
        dollar_addr = address(IDollar);

        IAccessControl.grantRole(
            keccak256("GOVERNANCE_TOKEN_MANAGER_ROLE"),
            admin
        );
        vm.stopPrank();
    }

    function testSetManager_ShouldRevert_WhenNotAdmin() public {
        vm.prank(address(0x123abc));
        vm.expectRevert("ERC20Ubiquity: not admin");
        IDollar.setManager(address(0x123abc));
    }

    function testSetManager_ShouldSetManager() public {
        address newDiamond = address(0x123abc);
        vm.prank(admin);
        IDollar.setManager(newDiamond);
        require(IDollar.getManager() == newDiamond);
    }

    function testSetIncentiveContract_ShouldRevert_IfNotAdmin() public {
        vm.prank(mock_sender);
        vm.expectRevert("Dollar: must have admin role");
        IDollar.setIncentiveContract(mock_sender, incentive_addr);

        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit IncentiveContractUpdate(mock_sender, incentive_addr);
        IDollar.setIncentiveContract(mock_sender, incentive_addr);
    }

    function testTransfer_ShouldCallIncentivize_IfValidTransfer() public {
        address userA = address(0x100001);
        address userB = address(0x100001);
        vm.startPrank(admin);
        IDollar.mint(userA, 100);
        IDollar.mint(userB, 100);
        IDollar.mint(mock_sender, 100);

        IDollar.setIncentiveContract(mock_sender, incentive_addr);
        IDollar.setIncentiveContract(mock_recipient, incentive_addr);
        IDollar.setIncentiveContract(mock_operator, incentive_addr);
        IDollar.setIncentiveContract(address(0), incentive_addr);
        IDollar.setIncentiveContract(dollar_addr, incentive_addr);
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
        IDollar.transfer(userB, 1);

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
        IDollar.transfer(mock_recipient, 1);
    }
}
