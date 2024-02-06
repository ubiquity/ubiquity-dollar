// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";

/**
 * @notice Curve MetaPool interface
 *
 * @notice **What is Curve MetaPool**
 * @notice The pool that consists of 2 tokens: stable coin and 3CRV LP token.
 * For example the pool may contain Ubiquity Dollar and 3CRV LP token.
 * This allows users to trade between Ubiquity Dollar and any of the tokens
 * from the Curve 3Pool (DAI, USDC, USDT). When user adds liquidity to the pool
 * then he is rewarded with MetaPool LP tokens. 1 Dollar3CRV LP token != 1 stable coin token.
 * @notice Add liquidity example:
 * 1. User sends 100 Ubiquity Dollars to the pool
 * 2. User gets 100 Dollar3CRV LP tokens of the pool
 * @notice Remove liquidity example:
 * 1. User sends 100 Dollar3CRV LP tokens to the pool
 * 2. User gets 100 Dollar/DAI/USDC/USDT (may choose any) tokens
 */
interface IMetaPool is IERC20 {
    /**
     * @notice Calculates the current effective TWAP balances given two
     * snapshots over time, and the time elapsed between the two snapshots
     * @param _first_balances First `price_cumulative_last` array that was snapshot via `get_price_cumulative_last()`
     * @param _last_balances Second `price_cumulative_last` array that was snapshot via `get_price_cumulative_last()`
     * @param _time_elapsed The elapsed time in seconds between `_first_balances` and `_last_balances`
     * @return Returns the `balances` of the TWAP value
     */
    function get_twap_balances(
        uint256[2] memory _first_balances,
        uint256[2] memory _last_balances,
        uint256 _time_elapsed
    ) external view returns (uint256[2] memory);

    /**
     * @notice Returns latest cumulative prices for pool tokens
     *
     * @notice The price P gets multiplied to how long it lasts T.
     * This is continuously added to cumulative value C.
     * Example:
     * 1. Timestamp 0, price 3000, C = 0
     * 2. Timestamp 200, price 3200, C = 0(previous C) + 3000 * 200 = 600000
     * 3. Timestamp 250, price 3150, C = 600000 + 3200 * 50 = 760000
     * 4. So TWAP between time (0,250) = (760000 - 0) / (250 - 0) = 3040
     *
     * @return Latest cumulative prices
     */
    function get_price_cumulative_last()
        external
        view
        returns (uint256[2] memory);

    /**
     * @notice Estimates the amount of LP tokens minted or burned based on a deposit or withdrawal
     *
     * @notice This calculation accounts for slippage, but not fees. It should be used as a basis for
     * determining expected amounts when calling `add_liquidity()` or `remove_liquidity_imbalance()`,
     * but should not be considered to be precise!
     *
     * @param _amounts Amount of each coin being deposited. Amounts correspond to the tokens at the
     * same index locations within `coins()`.
     * @param _is_deposit Set `True` for deposits, `False` for withdrawals
     * @return The expected amount of LP tokens minted or burned
     */
    function calc_token_amount(
        uint256[2] memory _amounts,
        bool _is_deposit
    ) external view returns (uint256);

    /**
     * @notice Deposits coins into to the pool and mints new LP tokens
     * @param _amounts List of amounts of underlying coins to deposit.
     * Amounts correspond to the tokens at the same index locations within `coins`.
     * @param _min_mint_amount Minimum amount of LP tokens to mint from the deposit
     * @param _receiver Optional address that receives the LP tokens. If not specified, they are sent to the caller.
     * @return The amount of LP tokens that were minted in the deposit
     */
    function add_liquidity(
        uint256[2] memory _amounts,
        uint256 _min_mint_amount,
        address _receiver
    ) external returns (uint256);

    /**
     * @notice Calculates the price for exchanging a token with index `i` to token
     * with index `j` and amount `dx` given the `_balances` provided
     * @param i The index of the coin being sent to the pool, as it related to the metapool
     * @param j The index of the coin being received from the pool, as it relates to the metapool
     * @param dx The amount of `i` being sent to the pool
     * @return Returns the quote / price as `dy` given `dx`
     */
    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    /**
     * @notice Calculates the price for exchanging a token with index `i` to token
     * with index `j` and amount `dx` given the `_balances` provided
     * @param i The index of the coin being sent to the pool, as it related to the metapool
     * @param j The index of the coin being received from the pool, as it relates to the metapool
     * @param dx The amount of `i` being sent to the pool
     * @param _balances The array of balances to be used for purposes of calculating the output
     * amount / exchange rate, this is the value returned in `get_twap_balances()`
     * @return Returns the quote / price as `dy` given `dx`
     */
    function get_dy(
        int128 i,
        int128 j,
        uint256 dx,
        uint256[2] memory _balances
    ) external view returns (uint256);

    /**
     * @notice Gets the amount received (“dy”) when swapping between two underlying assets within the pool
     * @notice Index values can be found using `get_underlying_coins()` within the factory contract
     * @param i Index value of the token to send
     * @param j Index value of the token to receive
     * @param dx The amount of `i` being exchanged
     * @return Returns the amount of `j` received
     */
    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    /**
     * @notice Performs an exchange between two tokens. Index values can be found
     * using the `coins()` public getter method, or `get_coins()` within the factory contract.
     * @param i Index value of the token to send
     * @param j Index value of the token to receive
     * @param dx The amount of `i` being exchanged
     * @param min_dy The minimum amount of `j` to receive. If the swap would result in less, the transaction will revert.
     * @return The amount of `j` received in the exchange
     */
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    /**
     * @notice Withdraws a single asset from the pool
     * @param _burn_amount Amount of LP tokens to burn in the withdrawal
     * @param i Index value of the coin to withdraw. Can be found using the `coins()` getter method.
     * @param _min_received Minimum amount of the coin to receive
     * @return The amount of the coin received in the withdrawal
     */
    function remove_liquidity_one_coin(
        uint256 _burn_amount,
        int128 i,
        uint256 _min_received
    ) external returns (uint256);

    /**
     * @notice Returns token address by the provided `arg0` index
     * @param arg0 Token index
     * @return Token address
     */
    function coins(uint256 arg0) external view returns (address);

    /**
     * @notice Returns token balances by `arg0` index
     * @param arg0 Token index
     * @return Token balance
     */
    function balances(uint256 arg0) external view returns (uint256);

    function fee() external view returns (uint256);

    /**
     * @notice Returns the latest timestamp when TWAP cumulative prices were updated
     * @return Latest update timestamp
     */
    function block_timestamp_last() external view returns (uint256);
}
