# TWAPOracleDollar3poolFacet
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/7c3a0bb87e5e9b32000b3291b4e7da4b119ff3fa/src/dollar/facets/TWAPOracleDollar3poolFacet.sol)

**Inherits:**
[Modifiers](/src/dollar/libraries/LibAppStorage.sol/contract.Modifiers.md), [ITWAPOracleDollar3pool](/src/dollar/interfaces/ITWAPOracleDollar3pool.sol/interface.ITWAPOracleDollar3pool.md)

Facet used for Curve TWAP oracle in the Dollar MetaPool


## Functions
### setPool

Sets Curve MetaPool to be used as a TWAP oracle


```solidity
function setPool(address _pool, address _curve3CRVToken1) external onlyOwner;
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
function update() external;
```

### consult

Returns the quote for the provided `token` address

If the `token` param is Dollar then returns 3CRV LP / Dollar quote

If the `token` param is 3CRV LP then returns Dollar / 3CRV LP quote

*This will always return 0 before update has been called successfully for the first time*


```solidity
function consult(address token) external view returns (uint256 amountOut);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|Token address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`amountOut`|`uint256`|Token price, Dollar / 3CRV LP or 3CRV LP / Dollar quote|


