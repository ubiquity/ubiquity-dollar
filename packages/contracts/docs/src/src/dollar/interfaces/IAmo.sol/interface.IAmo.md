# IAmo
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/7eb880f4fba21494d313924cfb57f6e8dfbc5078/src/dollar/interfaces/IAmo.sol)


## Functions
### returnCollateralToMinter

Returns collateral back to the AMO minter


```solidity
function returnCollateralToMinter(uint256 collateralAmount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralAmount`|`uint256`|Amount of collateral to return|


### setAmoMinter

Sets the address of the AMO minter


```solidity
function setAmoMinter(address _amoMinterAddress) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_amoMinterAddress`|`address`|New address of the AMO minter|


