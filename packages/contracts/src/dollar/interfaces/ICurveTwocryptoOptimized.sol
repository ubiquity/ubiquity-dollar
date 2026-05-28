// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ICurveStableSwapMetaNG} from "./ICurveStableSwapMetaNG.sol";

/**
 * @notice Curve's CurveTwocryptoOptimized interface
 *
 * @dev Differences between Curve's crypto and stable swap meta pools (and how Ubiquity organization uses them):
 * 1. They contain different tokens:
 * a) Curve's stable swap metapool contains Dollar/3CRVLP pair
 * b) Curve's crypto pool contains Governance/ETH pair
 * 2. They use different bonding curve shapes:
 * a) Curve's stable swap metapool is more straight (because underlying tokens are pegged to USD)
 * b) Curve's crypto pool resembles Uniswap's bonding curve (because underlying tokens are not USD pegged)
 * 3. The `price_oracle()` method works differently:
 * a) Curve's stable swap metapool `price_oracle(uint256 i)` accepts coin index parameter
 * b) Curve's crypto pool `price_oracle()` doesn't accept coin index parameter and always returns oracle price for coin at index 1
 *
 * @dev Basically `ICurveTwocryptoOptimized` has the same interface as `ICurveStableSwapMetaNG`
 * but we distinguish them in the code for clarity.
 */
interface ICurveTwocryptoOptimized is ICurveStableSwapMetaNG {
    /**
     * @notice Getter for the oracle price of the coin at index 1 with regard to the coin at index 0.
     * The price oracle is an exponential moving average with a periodicity determined by `ma_time`.
     * @return Price oracle
     */
    function price_oracle() external view returns (uint256);
}
