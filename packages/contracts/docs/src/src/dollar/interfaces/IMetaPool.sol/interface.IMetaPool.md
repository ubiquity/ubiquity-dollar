# IMetaPool
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/940040226cc8480b0e7aa65d1592259dfcf013ef/src/dollar/interfaces/IMetaPool.sol)

**Inherits:**
IERC20

Curve MetaPool interface

**What is Curve MetaPool**

The pool that consists of 2 tokens: stable coin and 3CRV LP token.
For example the pool may contain Ubiquity Dollar and 3CRV LP token.
This allows users to trade between Ubiquity Dollar and any of the tokens
from the Curve 3Pool (DAI, USDC, USDT). When user adds liquidity to the pool
then he is rewarded with MetaPool LP tokens. 1 Dollar3CRV LP token != 1 stable coin token.

Add liquidity example:
1. User sends 100 Ubiquity Dollars to the pool
2. User gets 100 Dollar3CRV LP tokens of the pool

Remove liquidity example:
1. User sends 100 Dollar3CRV LP tokens to the pool
2. User gets 100 Dollar/DAI/USDC/USDT (may choose any) tokens


## Functions
### get_twap_balances

Calculates the current effective TWAP balances given two
snapshots over time, and the time elapsed between the two snapshots


```solidity
function get_twap_balances(uint256[2] memory _first_balances, uint256[2] memory _last_balances, uint256 _time_elapsed)
    external
    view
    returns (uint256[2] memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_first_balances`|`uint256[2]`|First `price_cumulative_last` array that was snapshot via `get_price_cumulative_last()`|
|`_last_balances`|`uint256[2]`|Second `price_cumulative_last` array that was snapshot via `get_price_cumulative_last()`|
|`_time_elapsed`|`uint256`|The elapsed time in seconds between `_first_balances` and `_last_balances`|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256[2]`|Returns the `balances` of the TWAP value|


### get_price_cumulative_last

Returns latest cumulative prices for pool tokens

The price P gets multiplied to how long it lasts T.
This is continuously added to cumulative value C.
Example:
1. Timestamp 0, price 3000, C = 0
2. Timestamp 200, price 3200, C = 0(previous C) + 3000 * 200 = 600000
3. Timestamp 250, price 3150, C = 600000 + 3200 * 50 = 760000
4. So TWAP between time (0,250) = (760000 - 0) / (250 - 0) = 3040


```solidity
function get_price_cumulative_last() external view returns (uint256[2] memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256[2]`|Latest cumulative prices|


### calc_token_amount

Estimates the amount of LP tokens minted or burned based on a deposit or withdrawal

This calculation accounts for slippage, but not fees. It should be used as a basis for
determining expected amounts when calling `add_liquidity()` or `remove_liquidity_imbalance()`,
but should not be considered to be precise!


```solidity
function calc_token_amount(uint256[2] memory _amounts, bool _is_deposit) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amounts`|`uint256[2]`|Amount of each coin being deposited. Amounts correspond to the tokens at the same index locations within `coins()`.|
|`_is_deposit`|`bool`|Set `True` for deposits, `False` for withdrawals|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The expected amount of LP tokens minted or burned|


### add_liquidity

Deposits coins into to the pool and mints new LP tokens


```solidity
function add_liquidity(uint256[2] memory _amounts, uint256 _min_mint_amount, address _receiver)
    external
    returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amounts`|`uint256[2]`|List of amounts of underlying coins to deposit. Amounts correspond to the tokens at the same index locations within `coins`.|
|`_min_mint_amount`|`uint256`|Minimum amount of LP tokens to mint from the deposit|
|`_receiver`|`address`|Optional address that receives the LP tokens. If not specified, they are sent to the caller.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of LP tokens that were minted in the deposit|


### get_dy

Calculates the price for exchanging a token with index `i` to token
with index `j` and amount `dx` given the `_balances` provided


```solidity
function get_dy(int128 i, int128 j, uint256 dx) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`i`|`int128`|The index of the coin being sent to the pool, as it related to the metapool|
|`j`|`int128`|The index of the coin being received from the pool, as it relates to the metapool|
|`dx`|`uint256`|The amount of `i` being sent to the pool|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Returns the quote / price as `dy` given `dx`|


### get_dy

Calculates the price for exchanging a token with index `i` to token
with index `j` and amount `dx` given the `_balances` provided


```solidity
function get_dy(int128 i, int128 j, uint256 dx, uint256[2] memory _balances) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`i`|`int128`|The index of the coin being sent to the pool, as it related to the metapool|
|`j`|`int128`|The index of the coin being received from the pool, as it relates to the metapool|
|`dx`|`uint256`|The amount of `i` being sent to the pool|
|`_balances`|`uint256[2]`|The array of balances to be used for purposes of calculating the output amount / exchange rate, this is the value returned in `get_twap_balances()`|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Returns the quote / price as `dy` given `dx`|


### get_dy_underlying

Gets the amount received (“dy”) when swapping between two underlying assets within the pool

Index values can be found using `get_underlying_coins()` within the factory contract


```solidity
function get_dy_underlying(int128 i, int128 j, uint256 dx) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`i`|`int128`|Index value of the token to send|
|`j`|`int128`|Index value of the token to receive|
|`dx`|`uint256`|The amount of `i` being exchanged|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Returns the amount of `j` received|


### exchange

Performs an exchange between two tokens. Index values can be found
using the `coins()` public getter method, or `get_coins()` within the factory contract.


```solidity
function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy) external returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`i`|`int128`|Index value of the token to send|
|`j`|`int128`|Index value of the token to receive|
|`dx`|`uint256`|The amount of `i` being exchanged|
|`min_dy`|`uint256`|The minimum amount of `j` to receive. If the swap would result in less, the transaction will revert.|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of `j` received in the exchange|


### remove_liquidity_one_coin

Withdraws a single asset from the pool


```solidity
function remove_liquidity_one_coin(uint256 _burn_amount, int128 i, uint256 _min_received) external returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_burn_amount`|`uint256`|Amount of LP tokens to burn in the withdrawal|
|`i`|`int128`|Index value of the coin to withdraw. Can be found using the `coins()` getter method.|
|`_min_received`|`uint256`|Minimum amount of the coin to receive|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|The amount of the coin received in the withdrawal|


### coins

Returns token address by the provided `arg0` index


```solidity
function coins(uint256 arg0) external view returns (address);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`arg0`|`uint256`|Token index|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|Token address|


### balances

Returns token balances by `arg0` index


```solidity
function balances(uint256 arg0) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`arg0`|`uint256`|Token index|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Token balance|


### fee


```solidity
function fee() external view returns (uint256);
```

### block_timestamp_last

Returns the latest timestamp when TWAP cumulative prices were updated


```solidity
function block_timestamp_last() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Latest update timestamp|


