// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.19;

import {UbiquityPoolFacet} from "../../../src/dollar/facets/UbiquityPoolFacet.sol";

/// @notice Harness for Certora verification of LibUbiquityPool
contract PoolFacetHarness is UbiquityPoolFacet {
    /// @dev Expose reentrancy status for verification
    function exposed_getReentrancyStatus() external view returns (uint256) {
        return LibAppStorage.appStorage().reentrancyStatus;
    }
}

import {LibAppStorage} from "../../../src/dollar/libraries/LibAppStorage.sol";
