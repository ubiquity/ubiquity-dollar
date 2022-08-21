// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/UbiquityAlgorithmicDollarManager.sol";
import "../src/UbiquityAlgorithmicDollar.sol";

contract UbiquityAlgorithmicDollarScript is Script {
    function run() public {
        vm.startBroadcast();
        UbiquityAlgorithmicDollarManager ubiquityAlgorithmicDollarManager = new UbiquityAlgorithmicDollarManager(
                address(0x1)
            );
        address manager = address(ubiquityAlgorithmicDollarManager);

        new UbiquityAlgorithmicDollar(manager);
        vm.stopBroadcast();
    }
}
