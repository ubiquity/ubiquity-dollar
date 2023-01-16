// SPDX-License-Identifier: MIT
pragma solidity >=0.8.3;

interface IDepositZap {
    function add_liquidity(
        address _pool,
        uint256[4] calldata _amounts, //Ubiquity Dollar, DAI, USDC, USDT
        uint256 _min_mint_amount
    ) external returns (uint256 lpAmount);

    function remove_liquidity_one_coin(
        address _pool,
        uint256 lpAmount,
        int128 i,
        uint256 min_amount
    ) external returns (uint256 coinAmount);

    function remove_liquidity(
        address _pool,
        uint256 _amount,
        uint256[4] calldata min_amounts
    ) external returns (uint256[4] calldata);
}
