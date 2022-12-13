// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.16;

import "../interfaces/IMetaPool.sol";
import "../interfaces/ITWAPOracleDollar3pool.sol";

contract TWAPOracleDollar3pool is ITWAPOracle {
    address public immutable pool;
    address public immutable token0;
    address public immutable token1;
    uint256 public uADPrice;
    uint256 public curve3CRVAverage;
    uint256 public pricesBlockTimestampLast;
    uint256[2] public priceCumulativeLast;

    constructor(address _pool, address _uADtoken0, address _curve3CRVToken1) {
        pool = _pool;
        // coin at index 0 is uAD and index 1 is 3CRV
        require(
            IMetaPool(_pool).coins(0) == _uADtoken0
                && IMetaPool(_pool).coins(1) == _curve3CRVToken1,
            "TWAPOracle: COIN_ORDER_MISMATCH"
        );

        token0 = _uADtoken0;
        token1 = _curve3CRVToken1;

        uint256 _reserve0 = uint112(IMetaPool(_pool).balances(0));
        uint256 _reserve1 = uint112(IMetaPool(_pool).balances(1));

        // ensure that there's liquidity in the pair
        require(_reserve0 != 0 && _reserve1 != 0, "TWAPOracle: NO_RESERVES");
        // ensure that pair balance is perfect
        require(_reserve0 == _reserve1, "TWAPOracle: PAIR_UNBALANCED");
        priceCumulativeLast = IMetaPool(_pool).get_price_cumulative_last();
        pricesBlockTimestampLast = IMetaPool(_pool).block_timestamp_last();

        uADPrice = 1 ether;
        curve3CRVAverage = 1 ether;
    }

    // calculate average price
    function update() external {
        (uint256[2] memory priceCumulative, uint256 blockTimestamp) =
            _currentCumulativePrices();

        if (blockTimestamp - pricesBlockTimestampLast > 0) {
            // get the balances between now and the last price cumulative snapshot
            uint256[2] memory twapBalances = IMetaPool(pool).get_twap_balances(
                priceCumulativeLast,
                priceCumulative,
                blockTimestamp - pricesBlockTimestampLast
            );

            // price to exchange amounIn uAD to 3CRV based on TWAP
            uADPrice = IMetaPool(pool).get_dy(0, 1, 1 ether, twapBalances);
            // price to exchange amounIn 3CRV to uAD  based on TWAP
            curve3CRVAverage = IMetaPool(pool).get_dy(1, 0, 1 ether, twapBalances);
            // we update the priceCumulative
            priceCumulativeLast = priceCumulative;
            pricesBlockTimestampLast = blockTimestamp;
        }
    }

    // note this will always return 0 before update has been called successfully
    // for the first time.
    function consult(address token) external view returns (uint256 amountOut) {
        if (token == token0) {
            // price to exchange 1 uAD to 3CRV based on TWAP
            amountOut = uADPrice;
        } else {
            require(token == token1, "TWAPOracle: INVALID_TOKEN");
            // price to exchange 1 3CRV to uAD  based on TWAP
            amountOut = curve3CRVAverage;
        }
    }

    function _currentCumulativePrices()
        internal
        view
        returns (uint256[2] memory priceCumulative, uint256 blockTimestamp)
    {
        priceCumulative = IMetaPool(pool).get_price_cumulative_last();
        blockTimestamp = IMetaPool(pool).block_timestamp_last();
    }
}
