// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/UbiquityAlgorithmicDollarManager.sol";

contract UbiquityAlgorithmicDollarManagerScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        new UbiquityAlgorithmicDollarManager(address(0x1));
        vm.stopBroadcast();
    }
}
