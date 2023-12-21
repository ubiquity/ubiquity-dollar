# LibAppStorage
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/a1d9ec9e560cfbe04ba7ff62fe1103605f2a8cc7/src/dollar/libraries/LibAppStorage.sol)

Library used as a shared storage among all protocol libraries


## Functions
### appStorage

Returns `AppStorage` struct used as a shared storage among all libraries


```solidity
function appStorage() internal pure returns (AppStorage storage ds);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`ds`|`AppStorage`|`AppStorage` struct used as a shared storage|


