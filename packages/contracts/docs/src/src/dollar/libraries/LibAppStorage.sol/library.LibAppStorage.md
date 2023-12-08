# LibAppStorage
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/bc36823136700d0422c14fd5ae111920580c10d7/src/dollar/libraries/LibAppStorage.sol)

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


