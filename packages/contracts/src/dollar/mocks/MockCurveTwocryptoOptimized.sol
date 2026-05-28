// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ICurveTwocryptoOptimized} from "../interfaces/ICurveTwocryptoOptimized.sol";
import {MockCurveStableSwapMetaNG} from "./MockCurveStableSwapMetaNG.sol";

contract MockCurveTwocryptoOptimized is
    ICurveTwocryptoOptimized,
    MockCurveStableSwapMetaNG
{
    constructor(
        address _token0,
        address _token1
    ) MockCurveStableSwapMetaNG(_token0, _token1) {}

    function price_oracle() external view returns (uint256) {
        return priceOracle;
    }
}
