// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

import {ERC20Ubiquity} from "../../src/dollar/ERC20Ubiquity.sol";
import {UbiquityAlgorithmicDollarManager} from "../../src/dollar/UbiquityAlgorithmicDollarManager.sol";
import "../helpers/LocalTestHelper.sol";


contract ERC20UbiquityTest is LocalTestHelper {
    address token_addr;
    address uad_manager_addr;

    event Minting(address indexed mock_addr1, address indexed _minter, uint256 _amount);

    event Burning(address indexed _burned, uint256 _amount);

    function setUp() public {
        uad_manager_addr = helpers_deployUbiquityAlgorithmicDollarManager();
        vm.prank(admin);
        token_addr = address(new ERC20Ubiquity(uad_manager_addr, "Test", "Test"));
    }

    function test_setSymbol() public {
        vm.expectRevert("ERC20: deployer must be manager admin");
        ERC20Ubiquity(token_addr).setSymbol("Test1");

        vm.prank(admin);
        ERC20Ubiquity(token_addr).setSymbol("Test1");
        assertEq(ERC20Ubiquity(token_addr).symbol(), "Test1");
    }

    function test_setName() public {
        vm.expectRevert("ERC20: deployer must be manager admin");
        ERC20Ubiquity(token_addr).setName("Test1");

        vm.prank(admin);
        ERC20Ubiquity(token_addr).setName("Test1");
        assertEq(ERC20Ubiquity(token_addr).name(), "Test1");
    }

    function test_mintAndBurn() public {

        // test onlyMinter and mint
        address mock_addr1 = address(0x123);
        address mock_addr2 = address(0x234);
        vm.expectRevert("Governance token: not minter");
        ERC20Ubiquity(token_addr).mint(mock_addr1, 100);

        uint256 before_bal = ERC20Ubiquity(token_addr).balanceOf(mock_addr1);
        vm.prank(admin);
        vm.expectEmit(true, true, false, true);
        emit Minting(mock_addr1, admin, 100);
        ERC20Ubiquity(token_addr).mint(mock_addr1, 100);
        uint256 after_bal = ERC20Ubiquity(token_addr).balanceOf(mock_addr1);
        assertEq(after_bal - before_bal, 100);

        // test onlyPauser and check if transfer reverts
        vm.expectRevert("Governance token: not pauser");
        ERC20Ubiquity(token_addr).pause();
        vm.prank(admin);
        ERC20Ubiquity(token_addr).pause();
        vm.prank(mock_addr1);
        vm.expectRevert("Pausable: paused");
        ERC20Ubiquity(token_addr).transfer(mock_addr2, 10);

        vm.prank(admin);
        ERC20Ubiquity(token_addr).unpause();

        // test burn, onlyBurner and burnFrom
        before_bal = ERC20Ubiquity(token_addr).balanceOf(mock_addr1);
        vm.prank(mock_addr1);
        vm.expectEmit(true, false, false, true);
        emit Burning(mock_addr1, 10);
        ERC20Ubiquity(token_addr).burn(10);
        after_bal = ERC20Ubiquity(token_addr).balanceOf(mock_addr1);
        assertEq(before_bal - after_bal, 10);

        vm.prank(mock_addr2);
        vm.expectRevert("Governance token: not burner");
        ERC20Ubiquity(token_addr).burnFrom(mock_addr1, 10);

        before_bal = ERC20Ubiquity(token_addr).balanceOf(mock_addr1);
        vm.prank(admin);
        UbiquityAlgorithmicDollarManager(uad_manager_addr).grantRole(keccak256("UBQ_BURNER_ROLE"), mock_addr2);

        vm.prank(mock_addr2);
        vm.expectEmit(true, false, false, true);
        emit Burning(mock_addr1, 10);
        ERC20Ubiquity(token_addr).burnFrom(mock_addr1, 10);
        after_bal = ERC20Ubiquity(token_addr).balanceOf(mock_addr1);
        assertEq(before_bal - after_bal, 10);

    }
}
