// SPDX-License-Identifier: MIT

pragma solidity >= 0.8.3;

interface IStableSwap3Pool {
    function get_virtual_price() external view returns (uint256);
    function balances(uint256) external view returns (uint256);
    function coins(uint256) external view returns (address);
    function get_dy(int128 i, int128 j, uint256 dx)
        external
        view
        returns (uint256 dy);
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy)
        external;
    function add_liquidity(uint256[3] calldata amounts, uint256 min_mint_amount)
        external
        payable;
    function remove_liquidity(uint256 _amount, uint256[3] calldata amounts)
        external;
    function remove_liquidity_one_coin(
        uint256 _token_amount,
        int128 i,
        uint256 min_amount
    ) external;
    function calc_token_amount(uint256[3] calldata amounts, bool deposit)
        external
        view
        returns (uint256);
    function calc_withdraw_one_coin(uint256 _token_amount, int128 i)
        external
        view
        returns (uint256);
}
