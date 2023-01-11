// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
import "./core/UbiquityDollarManager.sol";

contract SushiSwapPool {
    IUniswapV2Factory constant factory =
        IUniswapV2Factory(0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac);

    UbiquityDollarManager public immutable manager;
    IUniswapV2Pair public pair;

    constructor(UbiquityDollarManager _manager) {
        manager = UbiquityDollarManager(_manager);
        require(
            manager.dollarTokenAddress() != address(0), "Dollar address not set"
        );
        require(
            manager.governanceTokenAddress() != address(0),
            "Governance token address not set"
        );
        // check if pair already exist
        address pool = factory.getPair(
            manager.dollarTokenAddress(), manager.governanceTokenAddress()
        );
        if (pool == address(0)) {
            pool = factory.createPair(
                manager.dollarTokenAddress(), manager.governanceTokenAddress()
            );
        }
        pair = IUniswapV2Pair(pool);
    }
}
