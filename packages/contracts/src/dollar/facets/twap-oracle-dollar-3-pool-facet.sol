// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.19;

import {LibTWAPOracle} from "../libraries/LibTWAPOracle.sol";
import {Modifiers} from "../libraries/LibAppStorage.sol";

import {ITWAPOracleDollar3pool} from "../../dollar/interfaces/ITWAPOracleDollar3pool.sol";

contract TWAPOracleDollar3poolFacet is Modifiers, ITWAPOracleDollar3pool {
    function setPool(
        address _pool,
        address _curve3CRVToken1
    ) external onlyOwner {
        return LibTWAPOracle.setPool(_pool, _curve3CRVToken1);
    }

    // calculate average price
    function update() external {
        LibTWAPOracle.update();
    }

    // note this will always return 0 before update has been called successfully
    // for the first time.
    function consult(address token) external view returns (uint256 amountOut) {
        return LibTWAPOracle.consult(token);
    }
}
