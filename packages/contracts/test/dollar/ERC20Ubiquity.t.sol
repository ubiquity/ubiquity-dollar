// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import "../helpers/LocalTestHelper.sol";
import {ERC20Ubiquity} from "../../src/dollar/ERC20Ubiquity.sol";

contract ERC20UbiquityTest is LocalTestHelper {
    address erc20Ubiquity_addr;

    function setUp() public {
        address uad_manager_addr = helpers_deployUbiquityAlgorithmicDollarManager();
        erc20Ubiquity_addr = address(new ERC20Ubiquity(uad_manager_addr, "Test", "Test"));
    }

    function test_setSymbol() public {
        vm.expectRevert("ERC20: deployer must be manager admin");
        ERC20Ubiquity(erc20Ubiquity_addr).setSymbol("Test1");

    }

    function test_setName() public {}

    
}