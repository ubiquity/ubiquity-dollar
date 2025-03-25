// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Interface for migrating LP tokens in the staking contract
interface IMigratorChef {
    /**
     * @notice Performs LP token migration from legacy UniswapV2 to SushiSwap.
     * @dev Migrator should have full access to the caller's LP token.
     * @dev Migrator must have allowance access to UniswapV2 LP tokens. 
     * @dev SushiSwap must mint EXACTLY the same amount of SushiSwap LP tokens or else something bad will happen. 
     * @dev Traditional UniswapV2 does not do that so be careful!
     * @param token Current LP token address
     * @return New LP token address
     */
    function migrate(IERC20 token) external returns (IERC20);
}
