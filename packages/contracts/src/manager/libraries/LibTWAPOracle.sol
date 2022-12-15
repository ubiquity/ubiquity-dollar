// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import "../../dollar/interfaces/IMetaPool.sol";

library LibTWAPOracle {
    struct TWAPOracleStorage {
        address pool;
        // address token0; will always be address(this)
        address token1;
        uint256 price0Average;
        uint256 price1Average;
        uint256 pricesBlockTimestampLast;
        uint256[2] priceCumulativeLast;
    }

    bytes32 public constant TWAP_ORACLE_STORAGE_POSITION =
        keccak256("diamond.standard.twap.oracle.storage");

    function _setPool(address _pool, address _curve3CRVToken1) internal {
        require(
            IMetaPool(_pool).coins(0) == address(this),
            "TWAPOracle: FIRST_COIN_NOT_DOLLAR"
        );
        TWAPOracleStorage storage ts = twapOracleStorage();

        // coin at index 0 is Ubiquity Dollar and index 1 is 3CRV
        require(
            IMetaPool(_pool).coins(1) == _curve3CRVToken1,
            "TWAPOracle: COIN_ORDER_MISMATCH"
        );

        uint256 _reserve0 = uint112(IMetaPool(_pool).balances(0));
        uint256 _reserve1 = uint112(IMetaPool(_pool).balances(1));

        // ensure that there's liquidity in the pair
        require(_reserve0 != 0 && _reserve1 != 0, "TWAPOracle: NO_RESERVES");
        // ensure that pair balance is perfect
        require(_reserve0 == _reserve1, "TWAPOracle: PAIR_UNBALANCED");
        ts.priceCumulativeLast = IMetaPool(_pool).get_price_cumulative_last();
        ts.pricesBlockTimestampLast = IMetaPool(_pool).block_timestamp_last();
        ts.pool = _pool;
        // dollar token is inside the diamond
        ts.token1 = _curve3CRVToken1;
        ts.price0Average = 1 ether;
        ts.price1Average = 1 ether;
    }

    function _update() internal {
        TWAPOracleStorage storage ts = twapOracleStorage();
        (
            uint256[2] memory priceCumulative,
            uint256 blockTimestamp
        ) = _currentCumulativePrices();

        if (blockTimestamp - ts.pricesBlockTimestampLast > 0) {
            // get the balances between now and the last price cumulative snapshot
            uint256[2] memory twapBalances = IMetaPool(ts.pool)
                .get_twap_balances(
                    ts.priceCumulativeLast,
                    priceCumulative,
                    blockTimestamp - ts.pricesBlockTimestampLast
                );

            // price to exchange amountIn Ubiquity Dollar to 3CRV based on TWAP
            ts.price0Average = IMetaPool(ts.pool).get_dy(
                0,
                1,
                1 ether,
                twapBalances
            );
            // price to exchange amountIn 3CRV to Ubiquity Dollar based on TWAP
            ts.price1Average = IMetaPool(ts.pool).get_dy(
                1,
                0,
                1 ether,
                twapBalances
            );
            // we update the priceCumulative
            ts.priceCumulativeLast = priceCumulative;
            ts.pricesBlockTimestampLast = blockTimestamp;
        }
    }

    function _consult(address token) internal view returns (uint256 amountOut) {
        TWAPOracleStorage memory ts = twapOracleStorage();
        if (token == address(this)) {
            // price to exchange 1 Ubiquity Dollar to 3CRV based on TWAP
            amountOut = ts.price0Average;
        } else {
            require(token == ts.token1, "TWAPOracle: INVALID_TOKEN");
            // price to exchange 1 3CRV to Ubiquity Dollar based on TWAP
            amountOut = ts.price1Average;
        }
    }

    function _currentCumulativePrices()
        internal
        view
        returns (uint256[2] memory priceCumulative, uint256 blockTimestamp)
    {
        address metapool = twapOracleStorage().pool;
        priceCumulative = IMetaPool(metapool).get_price_cumulative_last();
        blockTimestamp = IMetaPool(metapool).block_timestamp_last();
    }

    function twapOracleStorage()
        internal
        pure
        returns (TWAPOracleStorage storage ds)
    {
        bytes32 position = TWAP_ORACLE_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }
}
