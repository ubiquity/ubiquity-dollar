# LibTWAPOracle
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/7c3a0bb87e5e9b32000b3291b4e7da4b119ff3fa/src/dollar/libraries/LibTWAPOracle.sol)

Library used for Curve TWAP oracle in the Dollar MetaPool


## State Variables
### TWAP_ORACLE_STORAGE_POSITION
Storage slot used to store data for this library


```solidity
bytes32 constant TWAP_ORACLE_STORAGE_POSITION = bytes32(uint256(keccak256("diamond.standard.twap.oracle.storage")) - 1);
```


## Functions
### setPool

Sets Curve MetaPool to be used as a TWAP oracle


```solidity
function setPool(address _pool, address _curve3CRVToken1) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_pool`|`address`|Curve MetaPool address, pool for 2 tokens [Dollar, 3CRV LP]|
|`_curve3CRVToken1`|`address`|Curve 3Pool LP token address|


### update

Updates the following state variables to the latest values from MetaPool:
- Dollar / 3CRV LP quote
- 3CRV LP / Dollar quote
- cumulative prices
- update timestamp


```solidity
function update() internal;
```

### consult

Returns the quote for the provided `token` address

If the `token` param is Dollar then returns 3CRV LP / Dollar quote

If the `token` param is 3CRV LP then returns Dollar / 3CRV LP quote


```solidity
function consult(address token) internal view returns (uint256 amountOut);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|Token address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amountOut`|`uint256`|Token price, Dollar / 3CRV LP or 3CRV LP / Dollar quote|


### currentCumulativePrices

Returns current cumulative prices from metapool with updated timestamp


```solidity
function currentCumulativePrices() internal view returns (uint256[2] memory priceCumulative, uint256 blockTimestamp);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`priceCumulative`|`uint256[2]`|Current cumulative prices for pool tokens|
|`blockTimestamp`|`uint256`|Current update timestamp|


### twapOracleStorage

Returns struct used as a storage for this library


```solidity
function twapOracleStorage() internal pure returns (TWAPOracleStorage storage ds);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`ds`|`TWAPOracleStorage`|Struct used as a storage|


### getTwapPrice

Returns current Dollar price

*Returns 3CRV LP / Dollar quote, i.e. how many 3CRV LP tokens user will get for 1 Dollar*


```solidity
function getTwapPrice() internal view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Dollar price|


## Structs
### TWAPOracleStorage
Struct used as a storage for this library


```solidity
struct TWAPOracleStorage {
    address pool;
    address token1;
    uint256 price0Average;
    uint256 price1Average;
    uint256 pricesBlockTimestampLast;
    uint256[2] priceCumulativeLast;
}
```

