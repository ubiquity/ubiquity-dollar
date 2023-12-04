// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {UbiquityAlgorithmicDollarManager} from "../../src/deprecated/UbiquityAlgorithmicDollarManager.sol";
import {UbiquityGovernance} from "../../src/deprecated/UbiquityGovernance.sol";

/// @notice Migration contract
contract Deploy002_Governance is Script {
    // contracts
    UbiquityAlgorithmicDollarManager ubiquityAlgorithmicDollarManager;
    UbiquityGovernance ubiquityGovernance;

    function run() public virtual {
        // read env variables
        uint256 ownerPrivateKey = vm.envUint("OWNER_PRIVATE_KEY");

        address ownerAddress = vm.addr(ownerPrivateKey);

        // start sending owner transactions
        vm.startBroadcast(ownerPrivateKey);

        //===========================================
        // Deploy UbiquityAlgorithmicDollarManager
        //===========================================

        ubiquityAlgorithmicDollarManager = new UbiquityAlgorithmicDollarManager(
            ownerAddress
        );

        //===========================================
        // Deploy UbiquityGovernance
        //===========================================

        ubiquityGovernance = new UbiquityGovernance(
            address(ubiquityAlgorithmicDollarManager)
        );

        // stop sending owner transactions
        vm.stopBroadcast();
    }
}
