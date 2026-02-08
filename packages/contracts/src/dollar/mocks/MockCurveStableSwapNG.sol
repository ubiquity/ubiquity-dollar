// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ICurveStableSwapNG} from "../interfaces/ICurveStableSwapNG.sol";
import {MockCurveStableSwapMetaNG} from "./MockCurveStableSwapMetaNG.sol";

contract MockCurveStableSwapNG is
    ICurveStableSwapNG,
    MockCurveStableSwapMetaNG
{
    constructor(
        address _token0,
        address _token1
    ) MockCurveStableSwapMetaNG(_token0, _token1) {}

    function add_liquidity(
        uint256[] memory _amounts,
        uint256 _min_mint_amount,
        address _receiver
    ) external returns (uint256 result) {
        uint256[2] memory amounts = [_amounts[0], _amounts[1]];
        return add_liquidity(amounts, _min_mint_amount, _receiver);
    }
}
