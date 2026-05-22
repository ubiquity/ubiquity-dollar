// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {UbiquityPoolFacet} from "../../../../src/dollar/facets/UbiquityPoolFacet.sol";
import {LibUbiquityPool} from "../../../../src/dollar/libraries/LibUbiquityPool.sol";
import {AppStorage, LibAppStorage} from "../../../../src/dollar/libraries/LibAppStorage.sol";

/**
 * @notice Ubiquity pool facet harness for Certora formal verification
 * @notice Exposes internal state and critical view functions for invariant checking
 */
contract UbiquityPoolFacetHarness is UbiquityPoolFacet {
    /**
     * @notice Exposes the reentrancy status for safety verification
     * @return status 1 = entered, 2 = not entered
     */
    function exposed_getReentrancyStatus() external view returns (uint256) {
        AppStorage storage store = LibAppStorage.appStorage();
        return store.reentrancyStatus;
    }

    /**
     * @notice Exposes the collateral ratio for price-bound verification
     * @return collateralRatio 1_000_000 = 100%
     */
    function exposed_collateralRatio() external view returns (uint256) {
        return LibUbiquityPool.collateralRatio();
    }

    /**
     * @notice Exposes the total collateral USD balance
     * @return balance Collateral balance in USD terms
     */
    function exposed_collateralUsdBalance() external view returns (uint256) {
        return LibUbiquityPool.collateralUsdBalance();
    }

    /**
     * @notice Returns whether a collateral token is enabled
     * @param collateralAddress The collateral token address
     * @return isEnabled True if enabled
     */
    function exposed_isCollateralEnabled(address collateralAddress) external view returns (bool) {
        LibUbiquityPool.CollateralInformation memory info = LibUbiquityPool.collateralInformation(collateralAddress);
        return info.isEnabled;
    }

    /**
     * @notice Returns the collateral information for a given address
     * @param collateralAddress The collateral token address
     * @return returnData The collateral information struct
     */
    function exposed_collateralInformation(address collateralAddress)
        external
        view
        returns (LibUbiquityPool.CollateralInformation memory returnData)
    {
        return LibUbiquityPool.collateralInformation(collateralAddress);
    }

    /**
     * @notice Returns all collateral addresses
     * @return addresses Array of enabled collateral token addresses
     */
    function exposed_allCollaterals() external view returns (address[] memory) {
        return LibUbiquityPool.allCollaterals();
    }
}
