// contracts/GLDToken.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract MockMetaPool {
    address token0;
    address token1;
    address[2] public coins;
    uint256[2] public balances = [10e18, 10e18];
    uint256[2] public dy_values = [100e18, 100e18];
    uint256[2] price_cumulative_last = [10e18, 10e18];
    uint256 last_block_timestamp = 10000;

    constructor(address _token0, address _token1) {
        coins[0] = _token0;
        coins[1] = _token1;
    }

    function get_price_cumulative_last()
        external
        view
        returns (uint256[2] memory)
    {
        return price_cumulative_last;
    }

    function block_timestamp_last() external view returns (uint256) {
        return last_block_timestamp;
    }

    function get_twap_balances(
        uint256[2] memory _first_balances,
        uint256[2] memory _last_balances,
        uint256 _time_elapsed
    ) external view returns (uint256[2] memory) {
        return balances;
    }

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx,
        uint256[2] memory _balances
    ) external view returns (uint256) {
        if (i == 0 && j == 1) {
            return dy_values[1];
        } else if (i == 1 && j == 0) {
            return dy_values[0];
        } else {
            return 0;
        }
    }

    function updateMockParams(
        uint256[2] calldata _price_cumulative_last,
        uint256 _last_block_timestamp,
        uint256[2] calldata _twap_balances,
        uint256[2] calldata _dy_values
    ) public {
        price_cumulative_last = _price_cumulative_last;
        last_block_timestamp = _last_block_timestamp;
        balances = _twap_balances;
        dy_values = _dy_values;
    }

    function add_liquidity(
        uint256[2] memory _amounts,
        uint256 _min_mint_amount,
        address _receiver
    ) external pure returns (uint256) {
        return 100e18;
    }
}
