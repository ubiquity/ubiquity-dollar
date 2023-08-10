# LibAppStorage
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/3bd8ebfb9c040c43bc7387d834825102cd1e7687/src/dollar/libraries/LibAppStorage.sol)

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


