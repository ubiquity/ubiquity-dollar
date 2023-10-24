# MockMetaPool
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/7c3a0bb87e5e9b32000b3291b4e7da4b119ff3fa/src/dollar/mocks/MockMetaPool.sol)

**Inherits:**
[MockERC20](/src/dollar/mocks/MockERC20.sol/contract.MockERC20.md)


## State Variables
### token0

```solidity
address token0;
```


### token1

```solidity
address token1;
```


### coins

```solidity
address[2] public coins;
```


### balances

```solidity
uint256[2] public balances = [10e18, 10e18];
```


### dy_values

```solidity
uint256[2] public dy_values = [100e18, 100e18];
```


### price_cumulative_last

```solidity
uint256[2] price_cumulative_last = [10e18, 10e18];
```


### last_block_timestamp

```solidity
uint256 last_block_timestamp = 10000;
```


## Functions
### constructor


```solidity
constructor(address _token0, address _token1) MockERC20("Mock", "MCK", 18);
```

### get_price_cumulative_last


```solidity
function get_price_cumulative_last() external view returns (uint256[2] memory);
```

### block_timestamp_last


```solidity
function block_timestamp_last() external view returns (uint256);
```

### get_twap_balances


```solidity
function get_twap_balances(uint256[2] memory, uint256[2] memory, uint256) external view returns (uint256[2] memory);
```

### get_dy


```solidity
function get_dy(int128 i, int128 j, uint256, uint256[2] memory) external view returns (uint256);
```

### updateMockParams


```solidity
function updateMockParams(
    uint256[2] calldata _price_cumulative_last,
    uint256 _last_block_timestamp,
    uint256[2] calldata _twap_balances,
    uint256[2] calldata _dy_values
) public;
```

### add_liquidity


```solidity
function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount, address _receiver)
    external
    returns (uint256 result);
```

### calc_token_amount


```solidity
function calc_token_amount(uint256[2] memory _amounts, bool) external pure returns (uint256);
```

