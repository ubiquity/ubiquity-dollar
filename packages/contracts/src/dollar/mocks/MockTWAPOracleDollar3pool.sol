// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract MockTWAPOracleDollar3pool {
    address public immutable pool;
    address public immutable token0;
    address public immutable token1;
    uint256 public price0Average;
    uint256 public price1Average;
    uint256 public pricesBlockTimestampLast;
    uint256[2] public priceCumulativeLast;

    constructor(
        address _pool,
        address _dollarToken0,
        address _curve3CRVToken1,
        uint256 _price0Average,
        uint256 _price1Average
    ) {
        pool = _pool;

        token0 = _dollarToken0;
        token1 = _curve3CRVToken1;
        price0Average = _price0Average;
        price1Average = _price1Average;
    }

    function consult(address token) external view returns (uint256 amountOut) {
        if (token == token0) {
            // price to exchange amountIn Ubiquity Dollar to 3CRV based on TWAP
            amountOut = price0Average;
        } else {
            require(token == token1, "TWAPOracle: INVALID_TOKEN");
            // price to exchange amountIn 3CRV to Ubiquity Dollar based on TWAP
            amountOut = price1Average;
        }
    }

    function update() external pure {
        return;
    }
}
