// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/UbiquityAlgorithmicDollarManager.sol";
import "../src/UbiquityFormulas.sol";

contract UbiquityFormulasScript is Script {
    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        new UbiquityFormulas();
        vm.stopBroadcast();
    }
}
