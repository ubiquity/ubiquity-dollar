// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {ERC1155Ubiquity} from "../../src/dollar/ERC1155Ubiquity.sol";
import {UbiquityAlgorithmicDollarManager} from
    "../../src/dollar/UbiquityAlgorithmicDollarManager.sol";
import "../helpers/LocalTestHelper.sol";

contract ERC1155UbiquityTest is LocalTestHelper {
    address token_addr;
    address uad_manager_addr;

    event Minting(
        address indexed mock_addr1, address indexed _minter, uint256 _amount
    );

    event Burning(address indexed _burned, uint256 _amount);

    function setUp() public {
        uad_manager_addr = helpers_deployUbiquityAlgorithmicDollarManager();
        vm.prank(admin);
        token_addr = address(
            new ERC1155Ubiquity(uad_manager_addr, "https://ipfs.io/ipfs/mock")
        );
    }

    function test_mint() public {
        // mint
        address mock_addr1 = address(0x111);
        bytes memory data = abi.encode("mint");
        vm.expectRevert("Governance token: not minter");
        ERC1155Ubiquity(token_addr).mint(mock_addr1, 1, 10, data);

        uint256 before_total_supply = ERC1155Ubiquity(token_addr).totalSupply();
        vm.prank(admin);
        ERC1155Ubiquity(token_addr).mint(mock_addr1, 1, 10, data);
        uint256 after_total_supply = ERC1155Ubiquity(token_addr).totalSupply();
        assertEq(after_total_supply - before_total_supply, 10);
        uint256[] memory holder_tokens =
            ERC1155Ubiquity(token_addr).holderTokens(mock_addr1);
        uint256[] memory expected = new uint256[](1);
        expected[0] = 1;
        assertEq(holder_tokens, expected);

        // onlyPauser, pause and unpause
        vm.expectRevert("Governance token: not pauser");
        vm.prank(mock_addr1);
        ERC1155Ubiquity(token_addr).pause();

        vm.startPrank(admin);
        ERC1155Ubiquity(token_addr).pause();
        vm.expectRevert("ERC1155Pausable: token transfer while paused");
        ERC1155Ubiquity(token_addr).mint(mock_addr1, 1, 10, data);
        ERC1155Ubiquity(token_addr).unpause();
        vm.stopPrank();
    }

    function test_mintBatch() public {
        // mintBatch
        bytes memory data = abi.encode("mint");
        address mock_addr1 = address(0x111);
        uint256[] memory ids = new uint256[](2);
        ids[0] = 2;
        ids[1] = 3;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 100;
        vm.prank(admin);
        ERC1155Ubiquity(token_addr).mintBatch(mock_addr1, ids, amounts, data);
        uint256[] memory holder_tokens =
            ERC1155Ubiquity(token_addr).holderTokens(mock_addr1);
        uint256[] memory expected = new uint256[](2);
        expected[0] = 2;
        expected[1] = 3;
        assertEq(holder_tokens, expected);
        uint256 totalSupply = ERC1155Ubiquity(token_addr).totalSupply();
        assertEq(totalSupply, 200);
    }

    function test_safeTransferFrom() public {
        // mint some tokens to test out `safeTransferFrom`
        bytes memory data = abi.encode("transfer");
        address mock_addr1 = address(0x111);
        address mock_addr2 = address(0x112);
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 100;
        vm.prank(admin);
        ERC1155Ubiquity(token_addr).mintBatch(mock_addr1, ids, amounts, data);

        // safeTransferFrom
        vm.prank(mock_addr1);
        ERC1155Ubiquity(token_addr).safeTransferFrom(
            mock_addr1, mock_addr2, 1, 10, data
        );
        uint256[] memory holder_tokens =
            ERC1155Ubiquity(token_addr).holderTokens(mock_addr2);
        uint256[] memory expected = new uint256[](1);
        expected[0] = 1;
        assertEq(holder_tokens, expected);
    }

    function test_safeBatchTransferFrom() public {
        // mint some tokens to test out `safeBatchTransferFrom`
        bytes memory data = abi.encode("transfer");
        address mock_addr1 = address(0x111);
        address mock_addr2 = address(0x112);
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 100;
        vm.prank(admin);
        ERC1155Ubiquity(token_addr).mintBatch(mock_addr1, ids, amounts, data);

        // safeBatchTransferFrom
        uint256[] memory sending_amounts = new uint256[](2);
        sending_amounts[0] = 10;
        sending_amounts[1] = 10;
        vm.prank(mock_addr1);
        ERC1155Ubiquity(token_addr).safeBatchTransferFrom(
            mock_addr1, mock_addr2, ids, sending_amounts, data
        );
        uint256[] memory holder_tokens =
            ERC1155Ubiquity(token_addr).holderTokens(mock_addr2);
        uint256[] memory expected = new uint256[](2);
        expected[0] = 1;
        expected[1] = 2;
        assertEq(holder_tokens, expected);
    }

    function test_burnAndBurnBatch() public {
        // mint some tokens to test out `burn` and `burnBatch`
        bytes memory data = abi.encode("transfer");
        address mock_addr1 = address(0x111);
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 100;
        vm.prank(admin);
        ERC1155Ubiquity(token_addr).mintBatch(mock_addr1, ids, amounts, data);

        // burn
        uint256 before_total_supply = ERC1155Ubiquity(token_addr).totalSupply();
        vm.prank(mock_addr1);
        ERC1155Ubiquity(token_addr).burn(mock_addr1, 1, 10);
        uint256 after_total_supply = ERC1155Ubiquity(token_addr).totalSupply();
        assertEq(before_total_supply - after_total_supply, 10);

        // burnBatch
        uint256[] memory burning_amounts = new uint256[](2);
        burning_amounts[0] = 10;
        burning_amounts[1] = 10;
        before_total_supply = after_total_supply;
        vm.prank(mock_addr1);
        ERC1155Ubiquity(token_addr).burnBatch(mock_addr1, ids, burning_amounts);
        after_total_supply = ERC1155Ubiquity(token_addr).totalSupply();
        assertEq(before_total_supply - after_total_supply, 20);
    }
}
