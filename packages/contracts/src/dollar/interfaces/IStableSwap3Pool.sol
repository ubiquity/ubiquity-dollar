// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

/// @notice Curve TriPool interface
interface IStableSwap3Pool {
    /**
     * @notice The current virtual price of the pool LP token
     * @dev Useful for calculating profits
     * @return LP token virtual price normalized to 1e18
     */
    function get_virtual_price() external view returns (uint256);

    /**
     * @notice Returns pool balance
     * @return Token balance
     */
    function balances(uint256) external view returns (uint256);

    /**
     * @notice Returns coin address by index
     * @return Coin address
     */
    function coins(uint256) external view returns (address);

    /**
     * @notice Calculates the price for exchanging a token with index `i` to token
     * with index `j` and amount `dx` given the `_balances` provided
     * @param i The index of the coin being sent to the pool, as it related to the metapool
     * @param j The index of the coin being received from the pool, as it relates to the metapool
     * @param dx The amount of `i` being sent to the pool
     * @return dy Returns the quote / price as `dy` given `dx`
     */
    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256 dy);

    /**
     * @notice Performs an exchange between two tokens. Index values can be found
     * using the `coins()` public getter method, or `get_coins()` within the factory contract.
     * @param i Index value of the token to send
     * @param j Index value of the token to receive
     * @param dx The amount of `i` being exchanged
     * @param min_dy The minimum amount of `j` to receive. If the swap would result in less, the transaction will revert.
     */
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external;

    /**
     * @notice Deposits coins into to the pool and mints new LP tokens
     * @param amounts List of amounts of underlying coins to deposit.
     * Amounts correspond to the tokens at the same index locations within `coins`.
     * @param min_mint_amount Minimum amount of LP tokens to mint from the deposit
     */
    function add_liquidity(
        uint256[3] calldata amounts,
        uint256 min_mint_amount
    ) external payable;

    /**
     * @notice Withdraw coins from the pool
     * @dev Withdrawal amounts are based on current deposit ratios
     * @param _amount Quantity of LP tokens to burn in the withdrawal
     * @param amounts Minimum amounts of underlying coins to receive
     */
    function remove_liquidity(
        uint256 _amount,
        uint256[3] calldata amounts
    ) external;

    /**
     * @notice Withdraw a single coin from the pool
     * @param _token_amount Amount of LP tokens to burn in the withdrawal
     * @param i Index value of the coin to withdraw
     * @param min_amount Minimum amount of coin to receive
     */
    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;

    /**
     * @notice Calculate addition or reduction in token supply from a deposit or withdrawal
     * @dev This calculation accounts for slippage, but not fees.
     * Needed to prevent front-running, not for precise calculations!
     * @param amounts Amount of each coin being deposited
     * @param deposit set True for deposits, False for withdrawals
     */
    function calc_token_amount(
        uint256[3] calldata amounts,
        bool deposit
    ) external view returns (uint256);

    /**
     * @notice Calculate the amount received when withdrawing a single coin
     * @param _token_amount Amount of LP tokens to burn in the withdrawal
     * @param i Index value of the coin to withdraw
     */
    function calc_withdraw_one_coin(
        uint256 _token_amount,
        int128 i
    ) external view returns (uint256);
}
