// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {StakingFacet} from "../../src/dollar/facets/StakingFacet.sol";
import {AppStorage, LibAppStorage} from "../../src/dollar/libraries/LibAppStorage.sol";

/**
 * @notice Ubiquity staking facet harness
 */
contract StakingFacetHarness is StakingFacet {
    /**
     * @notice Returns reentrancy status, 1 - entered, 2 - not entered
     * @return Reentrancy status
     */
    function exposed_getReentrancyStatus() external view returns (uint256) {
        AppStorage storage store = LibAppStorage.appStorage();
        return store.reentrancyStatus;
    }
}
