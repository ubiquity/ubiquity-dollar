// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @notice TWAP oracle interface for Curve MetaPool
 *
 * @notice **What is Curve 3Pool**
 * @notice The pool that consists of 3 tokens: DAI, USDC, USDT.
 * Users are free to trade (swap) those tokens. When user adds liquidity
 * to the pool then he is rewarded with the pool's LP token 3CRV.
 * 1 3CRV LP token != 1 stable coin token.
 * @notice Add liquidity example:
 * 1. User sends 5 USDC to the pool
 * 2. User gets 5 3CRV LP tokens
 * @notice Remove liquidity example:
 * 1. User sends 99 3CRV LP tokens
 * 2. User gets 99 USDT tokens
 *
 * @notice **What is Curve MetaPool**
 * @notice The pool that consists of 2 tokens: stable coin and 3CRV LP token.
 * For example the pool may contain Ubiquity Dollar and 3CRV LP token.
 * This allows users to trade between Ubiquity Dollar and any of the tokens
 * from the Curve 3Pool (DAI, USDC, USDT). When user adds liquidity to the pool
 * then he is rewarded with MetaPool LP tokens. 1 Dollar3CRV LP token != 1 stable coin token.
 * @notice Add liquidity example:
 * 1. User sends 100 Ubiquity Dollars to the pool
 * 2. User gets 100 Dollar3CRV LP tokens of the pool
 * @notice Remove liquidity example:
 * 1. User sends 100 Dollar3CRV LP tokens to the pool
 * 2. User gets 100 Dollar/DAI/USDC/USDT (may choose any) tokens
 */
interface ITWAPOracleDollar3pool {
    /**
     * @notice Updates the following state variables to the latest values from MetaPool:
     * - Dollar / 3CRV LP quote
     * - 3CRV LP / Dollar quote
     * - cumulative prices
     * - update timestamp
     */
    function update() external;

    /**
     * @notice Returns the quote for the provided `token` address
     * @notice If the `token` param is Dollar then returns 3CRV LP / Dollar quote
     * @notice If the `token` param is 3CRV LP then returns Dollar / 3CRV LP quote
     * @dev This will always return 0 before update has been called successfully for the first time
     * @param token Token address
     * @return amountOut Token price, Dollar / 3CRV LP or 3CRV LP / Dollar quote
     */
    function consult(address token) external view returns (uint256 amountOut);
}
