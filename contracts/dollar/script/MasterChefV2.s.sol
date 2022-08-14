// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.3;

import "forge-std/Script.sol";
import "../src/MasterChefV2.sol";

contract MasterChefV2Script is Script {
    address MANAGER_ADDRESS = 0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98;
    address[] ALREADY_MIGRATED = [
        0x89eae71B865A2A39cBa62060aB1b40bbFFaE5b0D,
        0x4007CE2083c7F3E18097aeB3A39bb8eC149a341d,
        0x7c76f4DB70b7E2177de10DE3e2f668daDcd11108,
        0x0000CE08fa224696A819877070BF378e8B131ACF,
        0xa53A6fE2d8Ad977aD926C485343Ba39f32D3A3F6,
        0xCEFD0E73cC48B0b9d4C8683E52B7d7396600AbB2
    ];

    uint256[] AMOUNTS = [
        1301000000000000000,
        74603879373206500005186,
        44739174270101943975392,
        1480607760433248019987,
        9351040526163838324896,
        8991650309086743220575
    ];

    uint256[] IDS = [1, 2, 3, 4, 5, 6];

    function run() public {
        vm.startBroadcast();
        new MasterChefV2(MANAGER_ADDRESS, ALREADY_MIGRATED, AMOUNTS, IDS);
        vm.stopBroadcast();
    }
}
