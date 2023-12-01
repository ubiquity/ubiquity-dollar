// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @notice Collateral Oracle interface
 * @notice Returns price quotes for all registered collaterals
 */

interface ICollateralOracle {
    /**
     * @notice Updates the following state variables for each of the collaterals to the latest values
     * - collateral token / 3CRV LP quote
     * - cumulative prices
     * - update timestamp
     */
    function update() external;

    /**
     * @notice Returns the quote for the provided `token` address
     * @param token Token address
     * @return amountOut Token price
     */
    function consult(address token) external view returns (uint256 amountOut);
}
