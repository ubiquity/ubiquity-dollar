// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Script} from "forge-std/Script.sol";
import {UbiquityAlgorithmicDollarManager} from "../../src/deprecated/UbiquityAlgorithmicDollarManager.sol";
import {UbiquityGovernance} from "../../src/deprecated/UbiquityGovernance.sol";

/// @notice Migration contract
/// @dev This migration is used only for reference that we use already deployed
/// UbiquityAlgorithmicDollarManager and UbiquityGovernance contracts
contract Deploy002_Governance is Script {
    // contracts
    UbiquityAlgorithmicDollarManager ubiquityAlgorithmicDollarManager;
    UbiquityGovernance ubiquityGovernance;

    function run() public virtual {
        // using already deployed (on mainnet) UbiquityAlgorithmicDollarManager
        ubiquityAlgorithmicDollarManager = UbiquityAlgorithmicDollarManager(
            0x4DA97a8b831C345dBe6d16FF7432DF2b7b776d98
        );

        // using already deployed (on mainnet) Governance token
        ubiquityGovernance = UbiquityGovernance(
            0x4e38D89362f7e5db0096CE44ebD021c3962aA9a0
        );
    }
}
