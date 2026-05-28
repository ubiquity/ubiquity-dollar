// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";

import "../../src/ubiquistick/UbiquiStick.sol";
import "../../src/ubiquistick/UbiquiStickSale.sol";

contract UbiquiStickSaleTest is Test {
    UbiquiStick ubiquiStick;
    UbiquiStickSale ubiquiStickSale;

    // test users
    address owner;
    address user1;
    address user2;

    function setUp() public {
        owner = address(0x01);
        user1 = address(0x02);
        user2 = address(0x03);

        vm.startPrank(owner);
        ubiquiStick = new UbiquiStick();
        ubiquiStickSale = new UbiquiStickSale();
        vm.stopPrank();
    }

    function testSetTokenContract_ShouldRevert_IfCalledNotByOwner() public {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        ubiquiStickSale.setTokenContract(address(ubiquiStick));
    }

    function testSetTokenContract_ShouldRevert_IfAddressIsZero() public {
        vm.prank(owner);
        vm.expectRevert("Invalid Address");
        ubiquiStickSale.setTokenContract(address(0));
    }

    function testSetTokenContract_ShouldSetTokenContract() public {
        vm.prank(owner);
        ubiquiStickSale.setTokenContract(address(ubiquiStick));
        assertEq(
            address(ubiquiStickSale.tokenContract()),
            address(ubiquiStick)
        );
    }

    function testSetFundsAddress_ShouldRevert_IfCalledNotByOwner() public {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        ubiquiStickSale.setFundsAddress(address(0x03));
    }

    function testSetFundsAddress_ShouldRevert_IfAddressIsZero() public {
        vm.prank(owner);
        vm.expectRevert("Invalid Address");
        ubiquiStickSale.setFundsAddress(address(0));
    }

    function testSetFundsAddress_ShouldSetFundsAddress() public {
        vm.prank(owner);
        ubiquiStickSale.setFundsAddress(address(0x03));
        assertEq(ubiquiStickSale.fundsAddress(), address(0x03));
    }

    function testSetAllowance_ShouldRevert_IfCalledNotByOwner() public {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        ubiquiStickSale.setAllowance(user1, 1, 1);
    }

    function testSetAllowance_ShouldRevert_IfAddressIsZero() public {
        vm.prank(owner);
        vm.expectRevert("Invalid Address");
        ubiquiStickSale.setAllowance(address(0), 1, 1);
    }

    function testSetAllowance_ShouldSetAllowance() public {
        vm.prank(owner);
        ubiquiStickSale.setAllowance(user1, 1, 2);
        (uint256 count, uint256 price) = ubiquiStickSale.allowance(user1);
        assertEq(count, 1);
        assertEq(price, 2);
    }

    function testBatchSetAllowance_ShouldRevert_IfCalledNotByOwner() public {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        address[] memory targetAddresses;
        uint256[] memory targetCounts;
        uint256[] memory targetPrices;
        ubiquiStickSale.batchSetAllowances(
            targetAddresses,
            targetCounts,
            targetPrices
        );
    }

    function testBatchSetAllowance_ShouldBatchSetAllowance() public {
        address[] memory targetAddresses = new address[](2);
        targetAddresses[0] = user1;
        targetAddresses[1] = user2;

        uint256[] memory targetCounts = new uint[](2);
        targetCounts[0] = 1;
        targetCounts[1] = 2;

        uint256[] memory targetPrices = new uint[](2);
        targetPrices[0] = 3;
        targetPrices[1] = 4;

        vm.prank(owner);
        ubiquiStickSale.batchSetAllowances(
            targetAddresses,
            targetCounts,
            targetPrices
        );

        (uint256 count, uint256 price) = ubiquiStickSale.allowance(user1);
        assertEq(count, 1);
        assertEq(price, 3);

        (count, price) = ubiquiStickSale.allowance(user2);
        assertEq(count, 2);
        assertEq(price, 4);
    }

    function testAllowance_ShouldReturnAllowance() public {
        vm.prank(owner);
        ubiquiStickSale.setAllowance(user1, 1, 2);
        (uint256 count, uint256 price) = ubiquiStickSale.allowance(user1);
        assertEq(count, 1);
        assertEq(price, 2);
    }

    function testReceive_ShouldRevert_IfMaxSupplyIsReached() public {
        // owner whitelists user1
        vm.prank(owner);
        ubiquiStickSale.setAllowance(user1, 1, 1 ether);
        // mint 1024 tokens to user1
        vm.prank(owner);
        ubiquiStick.batchSafeMint(user1, 1024);
        // user1 tries to buy token
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        (bool isSuccess /* bytes memory data */, ) = address(ubiquiStickSale)
            .call{value: 1 ether}("");
        assertEq(isSuccess, false);
    }

    function testReceive_ShouldRevert_IfAllowanceIsInsufficient() public {
        // user1 tries to buy token
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        (bool success, ) = address(ubiquiStickSale).call{value: 1 ether}("");
        require(!success, "should have reverted due to insufficient allowance");
        (bool isSuccess /* bytes memory data */, ) = address(ubiquiStickSale)
            .call{value: 1 ether}("");
        assertEq(isSuccess, false);
    }

    function testWithdraw_ShouldRevert_IfCalledNotByOwner() public {
        vm.prank(user1);
        vm.expectRevert("Ownable: caller is not the owner");
        ubiquiStickSale.withdraw();
    }

    function testWithdraw_ShouldWithdraw() public {
        address fundsAddress = address(0x04);
        vm.deal(address(ubiquiStickSale), 1 ether);

        // set funds address where to withdraw
        vm.prank(owner);
        ubiquiStickSale.setFundsAddress(fundsAddress);

        // balances before
        assertEq(fundsAddress.balance, 0);
        assertEq(address(ubiquiStickSale).balance, 1 ether);

        // withdraw
        vm.prank(owner);
        ubiquiStickSale.withdraw();

        // balances after
        assertEq(fundsAddress.balance, 1 ether);
        assertEq(address(ubiquiStickSale).balance, 0);
    }
}
