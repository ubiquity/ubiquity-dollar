# IDollarAmoMinter
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/c016c6dc0daa0d788a6f4e197f9b9468d8d2c907/src/dollar/interfaces/IDollarAmoMinter.sol)

AMO minter interface

*AMO minter can borrow collateral from the Ubiquity Pool to make some yield*


## Functions
### collateralDollarBalance

Returns collateral Dollar balance


```solidity
function collateralDollarBalance() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Collateral Dollar balance|


### collateralIndex

Returns collateral index (from the Ubiquity Pool) for which AMO minter is responsible


```solidity
function collateralIndex() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Collateral token index|


