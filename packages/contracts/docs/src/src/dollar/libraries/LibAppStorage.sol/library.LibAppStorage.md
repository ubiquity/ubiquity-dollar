# LibAppStorage
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/cbd28a4612a3e634eb46789c9d7030bc45955983/src/dollar/libraries/LibAppStorage.sol)

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


