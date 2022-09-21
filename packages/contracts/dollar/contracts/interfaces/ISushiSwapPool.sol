// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

interface ISushiSwapPool {
    function pairInfo(address tokenA, address tokenB)
        external
        view
        returns (
            uint256 reserveA,
            uint256 reserveB,
            uint256 totalSupply
        );
}
