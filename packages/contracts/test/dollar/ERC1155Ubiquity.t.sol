// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {ERC1155Ubiquity} from "../../src/dollar/ERC1155Ubiquity.sol";
import {UbiquityAlgorithmicDollarManager} from "../../src/dollar/UbiquityAlgorithmicDollarManager.sol";
import "../helpers/LocalTestHelper.sol";


contract ERC1155UbiquityTest is LocalTestHelper {
    address token_addr;
    address uad_manager_addr;

    event Minting(address indexed mock_addr1, address indexed _minter, uint256 _amount);

    event Burning(address indexed _burned, uint256 _amount);

    function setUp() public {
        uad_manager_addr = helpers_deployUbiquityAlgorithmicDollarManager();
        vm.prank(admin);
        token_addr = address(new ERC1155Ubiquity(uad_manager_addr, "https://ipfs.io/ipfs/mock"));
    }

    function test_mint() public {
        
    }
}
