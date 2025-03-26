// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import {UbiquityAlgorithmicDollarManager} from "../../src/deprecated/UbiquityAlgorithmicDollarManager.sol";
import {UbiquityGovernance} from "../../src/deprecated/UbiquityGovernance.sol";
import {IERC20Ubiquity} from "../../src/deprecated/interfaces/IERC20Ubiquity.sol";
import {MockERC20} from "../../src/dollar/mocks/MockERC20.sol";
import {MasterChef} from "../../src/dollar/utils/MasterChef.sol";

contract MasterChefTest is Test {
    UbiquityAlgorithmicDollarManager dollarManager;
    UbiquityGovernance governanceToken;
    MasterChef masterChef;
    MockERC20 stakeToken;

    address owner = makeAddr("owner");
    address treasury = makeAddr("treasury");
    address user = makeAddr("user");

    function setUp() public {
        vm.prank(owner);
        dollarManager = new UbiquityAlgorithmicDollarManager(owner);

        vm.prank(owner);
        governanceToken = new UbiquityGovernance(address(dollarManager));

        vm.prank(owner);
        masterChef = new MasterChef(
            IERC20Ubiquity(governanceToken),
            treasury,
            100 ether, // tokens per block
            block.timestamp, // start from block
            0 // bonus end block
        );

        stakeToken = new MockERC20("STK", "STK", 18);

        // owner creates a new pool
        vm.prank(owner);
        masterChef.createStakingPool(
            100, // allocation points
            stakeToken,
            true
        );

        // owner grants MasterChef permission to mint Governance tokens
        vm.prank(owner);
        dollarManager.grantRole(keccak256("UBQ_MINTER_ROLE"), address(masterChef));
    }

    function testDeposit() public {
        stakeToken.mint(user, 100 ether);

        vm.prank(user);
        stakeToken.approve(address(masterChef), type(uint256).max);

        console2.log("===before===");
        console2.log("Balance user (STK):", stakeToken.balanceOf(user));
        console2.log("Balance MasterChef (STK):", stakeToken.balanceOf(address(masterChef)));

        vm.prank(user);
        masterChef.stake(
            0, // pool id
            100 ether // STK tokens staked
        );

        console2.log("===after===");
        console2.log("Balance user (STK):", uint256(stakeToken.balanceOf(user)));
        console2.log("Balance MasterChef (STK):", stakeToken.balanceOf(address(masterChef)));
    }

    function testWithdraw() public {
        stakeToken.mint(user, 100 ether);

        vm.prank(user);
        stakeToken.approve(address(masterChef), type(uint256).max);

        vm.prank(user);
        masterChef.stake(
            0, // pool id
            100 ether // STK tokens staked
        );

        vm.roll(block.number + 100);

        console2.log("===before===");
        console2.log("Balance user (STK):", stakeToken.balanceOf(user));
        console2.log("Balance MasterChef (STK):", stakeToken.balanceOf(address(masterChef)));
        console2.log("Balance user (UBQ):", governanceToken.balanceOf(user));
        console2.log("Balance MasterChef (UBQ):", governanceToken.balanceOf(address(masterChef)));

        vm.prank(user);
        masterChef.unstake(0, 100 ether);

        console2.log("===after===");
        console2.log("Balance user (STK):", uint256(stakeToken.balanceOf(user)));
        console2.log("Balance MasterChef (STK):", stakeToken.balanceOf(address(masterChef)));
        console2.log("Balance user (UBQ):", governanceToken.balanceOf(user));
        console2.log("Balance MasterChef (UBQ):", governanceToken.balanceOf(address(masterChef)));
    }
}
