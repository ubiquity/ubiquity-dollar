// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.19;

import {LibTWAPOracle} from "../libraries/LibTWAPOracle.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

import {ITWAPOracleDollar3pool} from "../../dollar/interfaces/ITWAPOracleDollar3pool.sol";

/**
 * @notice Facet used for Curve TWAP oracle in the Dollar MetaPool
 */
contract TWAPOracleDollar3poolFacet is Modifiers, ITWAPOracleDollar3pool {
    /**
     * @notice Sets Curve MetaPool to be used as a TWAP oracle
     * @param _pool Curve MetaPool address, pool for 2 tokens [Dollar, 3CRV LP]
     * @param _curve3CRVToken1 Curve 3Pool LP token address
     */
    function setPool(
        address _pool,
        address _curve3CRVToken1
    ) external onlyOwner {
        return LibTWAPOracle.setPool(_pool, _curve3CRVToken1);
    }

    /**
     * @notice Updates the following state variables to the latest values from MetaPool:
     * - Dollar / 3CRV LP quote
     * - 3CRV LP / Dollar quote
     * - cumulative prices
     * - update timestamp
     */
    function update() external {
        LibTWAPOracle.update();
    }

    /**
     * @notice Returns the quote for the provided `token` address
     * @notice If the `token` param is Dollar then returns 3CRV LP / Dollar quote
     * @notice If the `token` param is 3CRV LP then returns Dollar / 3CRV LP quote
     * @dev This will always return 0 before update has been called successfully for the first time
     * @param token Token address
     * @return amountOut Token price, Dollar / 3CRV LP or 3CRV LP / Dollar quote
     */
    function consult(address token) external view returns (uint256 amountOut) {
        return LibTWAPOracle.consult(token);
    }
}
