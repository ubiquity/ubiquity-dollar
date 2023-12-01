// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IMetaPool} from "../../dollar/interfaces/IMetaPool.sol";
import {AggregatorV3Interface} from "../../dollar/interfaces/AggregatorV3Interface.sol";
import {LibAppStorage} from "./LibAppStorage.sol";

/**
 * @notice Library used for Collateral price oracles
 * @dev Initially supports ChainLink price feeds
 * @dev This library may combine in the future different price feeds and Curve Metapool TWAPs
 * @dev List of available collateral tokens and their price is stored in LibUbiquityPool
 */
library LibCollateralOracle {
    /// @notice Struct used as a storage for this library
    struct CollateralOracleStorage {
        mapping(address => AggregatorV3Interface) priceFeeds;
    }

    /// @notice Emitted when collateral token price was updated
    event CollateralPriceUpdated(address token, uint256 price);

    /// @notice Storage slot used to store data for this library
    bytes32 constant COLLATERAL_ORACLE_STORAGE_POSITION =
        bytes32(
            uint256(keccak256("diamond.standard.collateral.oracle.storage")) - 1
        );

    /**
     * @notice Returns struct used as a storage for this library
     * @return ds Struct used as a storage
     */
    function collateralOracleStorage()
        internal
        pure
        returns (collateralOracleStorage storage ds)
    {
        bytes32 position = COLLATERAL_ORACLE_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /**
     * @notice Updates all registered collateral prices from ChainLink
     */
    function update() internal {}

    /**
     * @notice Returns the quote for the provided `token` address
     * @param token Token address
     * @return amountOut Token price vs 3CRV LP
     */
    function consult(address token) internal view returns (uint256) {}
}
