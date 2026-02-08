// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {ICurveStableSwapMetaNG} from "./ICurveStableSwapMetaNG.sol";

/**
 * @notice Curve's interface for plain pool which contains only USD pegged assets
 */
interface ICurveStableSwapNG is ICurveStableSwapMetaNG {
    function add_liquidity(
        uint256[] memory _amounts,
        uint256 _min_mint_amount,
        address _receiver
    ) external returns (uint256);
}
