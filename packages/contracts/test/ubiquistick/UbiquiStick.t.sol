// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../../src/ubiquistick/UbiquiStick.sol";
import "operator-filter-registry/OperatorFilterRegistryErrorsAndEvents.sol";
import "forge-std/Test.sol";

contract UbiquiStickTest is Test {
    // contract instance
    UbiquiStick ust;

    // addresses to test with
    address mintTo;
    address transferTo;
    address bannedOperator;
    address allowedOperator;

    // events
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function setUp() public {
        ust = new UbiquiStick();
        mintTo = 0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045;  // Vitalik's address
        transferTo = 0xc6b0562605D35eE710138402B878ffe6F2E23807; // Beeple's address
        bannedOperator = 0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329; // SudoSwap LSSVMPairRouter
        allowedOperator = 0x4feE7B061C97C9c496b01DbcE9CDb10c02f0a0Be; // Rarible NFT Transfer Proxy (for Approvals)
    }

    // MINT
    function testMint() public {
        assertEq(ust.balanceOf(mintTo), 0);
        ust.safeMint(mintTo);
        assertEq(ust.balanceOf(mintTo), 1);
        assertEq(ust.tokenIdNext(), 2);
    }

    // APPROVALS
    function testApproveForBannedOperator() public {
        // mint NFT to vitalik's address
        ust.safeMint(mintTo);

        // Approval for banned operator should fail with the AddressFiltered(address filtered) error
        vm.expectRevert(abi.encodeWithSelector(OperatorFilterRegistryErrorsAndEvents.AddressFiltered.selector, bannedOperator));
        vm.prank(mintTo);
        ust.approve(bannedOperator, 1);
    }

    function testSetApprovalsAllForBannedOperator() public {
        // mint NFT to vitalik's address
        ust.safeMint(mintTo);

        // Approval for banned operator should fail with the AddressFiltered(address filtered) error
        vm.expectRevert(abi.encodeWithSelector(OperatorFilterRegistryErrorsAndEvents.AddressFiltered.selector, bannedOperator));
        vm.prank(mintTo);
        ust.setApprovalForAll(bannedOperator, true);
    }

    function testApproveForAllowedOperator() public {
        // mint NFT to vitalik's address
        ust.safeMint(mintTo);

        // Approval for an allowed operator should work
        vm.startPrank(mintTo);
        vm.expectEmit(true, true, false, true);
        emit Approval(mintTo, allowedOperator, 1);
        ust.approve(allowedOperator, 1);
        vm.stopPrank();
    }

    function testSetApprovalsAllForAllowedOperator() public {
        // mint NFT to vitalik's address
        ust.safeMint(mintTo);

        // Approval for an allowed operator should work
        vm.startPrank(mintTo);
        vm.expectEmit(true, true, false, true);
        emit ApprovalForAll(mintTo, allowedOperator, true);
        ust.setApprovalForAll(allowedOperator, true);
        vm.stopPrank();
    }

    // TRANSFERS
    function testTransferFromForBannedOperator() public {
        // mint NFT to vitalik's address
        ust.safeMint(mintTo);

        // Approval for banned operator should fail with the AddressFiltered(address filtered) error
        vm.expectRevert(abi.encodeWithSelector(OperatorFilterRegistryErrorsAndEvents.AddressFiltered.selector, bannedOperator));
        vm.prank(mintTo);
        ust.approve(bannedOperator, 1);

        // transferFrom vitalik's address to Beeple's address should also fail with the AddressFiltered(address filtered) error
        vm.expectRevert(abi.encodeWithSelector(OperatorFilterRegistryErrorsAndEvents.AddressFiltered.selector, bannedOperator));
        vm.prank(bannedOperator);
        ust.transferFrom(mintTo, transferTo, 1);
    }

    function testSafeTransferFromForBannedOperator() public {
        // mint NFT to vitalik's address
        ust.safeMint(mintTo);

        // Approval for banned operator should fail with the AddressFiltered(address filtered) error
        vm.expectRevert(abi.encodeWithSelector(OperatorFilterRegistryErrorsAndEvents.AddressFiltered.selector, bannedOperator));
        vm.prank(mintTo);
        ust.approve(bannedOperator, 1);

        // safeTransferFrom vitalik's address to Beeple's address should also fail with the AddressFiltered(address filtered) error
        vm.expectRevert(abi.encodeWithSelector(OperatorFilterRegistryErrorsAndEvents.AddressFiltered.selector, bannedOperator));
        vm.prank(bannedOperator);
        ust.safeTransferFrom(mintTo, transferTo, 1);
    }

    function testSafeTransferFromWithDataForBannedOperator() public {
        // mint NFT to vitalik's address
        ust.safeMint(mintTo);

        // Approval for banned operator should fail with the AddressFiltered(address filtered) error
        vm.expectRevert(abi.encodeWithSelector(OperatorFilterRegistryErrorsAndEvents.AddressFiltered.selector, bannedOperator));
        vm.prank(mintTo);
        ust.approve(bannedOperator, 1);

        // safeTransferFrom vitalik's address to Beeple's address should also fail with the AddressFiltered(address filtered) error
        vm.expectRevert(abi.encodeWithSelector(OperatorFilterRegistryErrorsAndEvents.AddressFiltered.selector, bannedOperator));
        vm.prank(bannedOperator);
        ust.safeTransferFrom(mintTo, transferTo, 1, new bytes(0));
    }

    function testTransferFromForAllowedOperator() public {
        // mint NFT to vitalik's address
        ust.safeMint(mintTo);

        // Approval for an allowed operator should work
        vm.startPrank(mintTo);
        vm.expectEmit(true, true, false, true);
        emit Approval(mintTo, allowedOperator, 1);
        ust.approve(allowedOperator, 1);
        vm.stopPrank();

        // Approved allowed operator should be able to transfer NFT to Beeple's address
        vm.startPrank(allowedOperator);
        uint256 beforeBalance = ust.balanceOf(transferTo);
        vm.expectEmit(true, true, true, true);
        emit Transfer(mintTo, transferTo, 1);
        ust.transferFrom(mintTo, transferTo, 1);
        uint256 afterBalance = ust.balanceOf(transferTo);
        assertEq(afterBalance - beforeBalance, 1);
        vm.stopPrank();
    }

    function testSafeTransferFromForAllowedOperator() public {
        // mint NFT to vitalik's address
        ust.safeMint(mintTo);

        // Approval for an allowed operator should work
        vm.startPrank(mintTo);
        vm.expectEmit(true, true, false, true);
        emit Approval(mintTo, allowedOperator, 1);
        ust.approve(allowedOperator, 1);
        vm.stopPrank();

        // Approved allowed operator should be able to transfer NFT to Beeple's address
        vm.startPrank(allowedOperator);
        uint256 beforeBalance = ust.balanceOf(transferTo);
        vm.expectEmit(true, true, true, true);
        emit Transfer(mintTo, transferTo, 1);
        ust.safeTransferFrom(mintTo, transferTo, 1);
        uint256 afterBalance = ust.balanceOf(transferTo);
        assertEq(afterBalance - beforeBalance, 1);
        vm.stopPrank();
    }

    function testSafeTransferFromWithDataForAllowedOperator() public {
        // mint NFT to vitalik's address
        ust.safeMint(mintTo);

        // Approval for an allowed operator should work
        vm.startPrank(mintTo);
        vm.expectEmit(true, true, false, true);
        emit Approval(mintTo, allowedOperator, 1);
        ust.approve(allowedOperator, 1);
        vm.stopPrank();

        // Approved allowed operator should be able to transfer NFT to Beeple's address
        vm.startPrank(allowedOperator);
        uint256 beforeBalance = ust.balanceOf(transferTo);
        vm.expectEmit(true, true, true, true);
        emit Transfer(mintTo, transferTo, 1);
        ust.safeTransferFrom(mintTo, transferTo, 1, new bytes(0));
        uint256 afterBalance = ust.balanceOf(transferTo);
        assertEq(afterBalance - beforeBalance, 1);
        vm.stopPrank();
    }

}
