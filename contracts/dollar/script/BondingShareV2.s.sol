// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/UbiquityAlgorithmicDollarManager.sol";
import "../src/BondingShareV2.sol";

contract BondingShareV2Script is Script {
    function setUp() public {}

    function run() public {
        string memory uri = "'name': 'Bonding Share'"
        "'description': 'Ubiquity Bonding Share V2'"
        "'https://bafybeifibz4fhk4yag5reupmgh5cdbm2oladke4zfd7ldyw7avgipocpmy.ipfs.infura-ipfs.io/'";

        vm.startBroadcast();
        UbiquityAlgorithmicDollarManager ubiquityAlgorithmicDollarManager = new UbiquityAlgorithmicDollarManager(
                address(0x1)
            );
        address manager = address(ubiquityAlgorithmicDollarManager);

        new BondingShareV2(manager, uri);
        vm.stopBroadcast();
    }
}
