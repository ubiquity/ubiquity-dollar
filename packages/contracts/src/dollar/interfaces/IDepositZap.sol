// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @notice Interface for Curve's Deposit Zap
 * @notice Deposit contracts (also known as “zaps”) allow users to add and remove liquidity
 * from a pool using the pool’s underlying tokens
 */
interface IDepositZap {
    /**
     * @notice Wrap underlying coins and deposit them into `_pool`
     * @param _pool Address of the pool to deposit into
     * @param _amounts List of amounts of underlying coins to deposit
     * @param _min_mint_amount Minimum amount of LP tokens to mint from the deposit
     * @return lpAmount Amount of LP tokens received by depositing
     */
    function add_liquidity(
        address _pool,
        uint256[4] calldata _amounts, //Ubiquity Dollar, DAI, USDC, USDT
        uint256 _min_mint_amount
    ) external returns (uint256 lpAmount);

    /**
     * @notice Withdraw and unwrap a single coin from the pool
     * @param _pool Address of the pool to withdraw from
     * @param lpAmount Amount of LP tokens to burn in the withdrawal
     * @param i Index value of the coin to withdraw
     * @param min_amount Minimum amount of underlying coin to receive
     * @return coinAmount Amount of underlying coin received
     */
    function remove_liquidity_one_coin(
        address _pool,
        uint256 lpAmount,
        int128 i,
        uint256 min_amount
    ) external returns (uint256 coinAmount);

    /**
     * @notice Withdraw and unwrap coins from the pool
     * @dev Withdrawal amounts are based on current deposit ratios
     * @param _pool Address of the pool to deposit into
     * @param _amount Quantity of LP tokens to burn in the withdrawal
     * @param min_amounts Minimum amounts of underlying coins to receive
     * @return List of amounts of underlying coins that were withdrawn
     */
    function remove_liquidity(
        address _pool,
        uint256 _amount,
        uint256[4] calldata min_amounts
    ) external returns (uint256[4] calldata);
}
