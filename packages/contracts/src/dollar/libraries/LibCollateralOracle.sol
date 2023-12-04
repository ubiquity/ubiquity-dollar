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
        mapping(address => AggregatorV3Interface) chainLinkPriceFeed;
    }

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
        returns (CollateralOracleStorage storage ds)
    {
        bytes32 position = COLLATERAL_ORACLE_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice(
        AggregatorV3Interface priceFeed
    ) public view returns (int) {
        (
            uint80 roundID,
            int price,
            ,
            uint256 updatedAt,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        require(
            price >= 0 && updatedAt != 0 && answeredInRound >= roundID,
            "Invalid ChainLink price"
        );

        return price;
    }

    /**
     * Returns collateral token price feed decimals
     */
    function getDecimals(
        AggregatorV3Interface priceFeed
    ) public view returns (uint8) {
        return priceFeed.decimals();
    }

    /**
     * @notice Registers ChainLink price feed for a token vs 3CRV
     */
    function registerChainLinkPriceFeed(
        address token,
        address feedContractAddress
    ) internal {
        CollateralOracleStorage storage cs = collateralOracleStorage();

        cs.chainLinkPriceFeed[token] = AggregatorV3Interface(
            feedContractAddress
        );
    }

    /**
     * @notice Returns the quote for the provided `token` address
     * @dev currently uses ChainLink price feed
     * @param token Token address
     * @return amountOut Token price vs 3CRV LP
     */
    function consult(address token) internal view returns (int) {
        CollateralOracleStorage storage cs = collateralOracleStorage();

        return getLatestPrice(cs.chainLinkPriceFeed[token]);
    }
}
