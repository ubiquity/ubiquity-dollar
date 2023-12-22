# LibAppStorage
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/40df6b48aeb8f52a1ca16fc758a5459764bee6c2/src/dollar/libraries/LibAppStorage.sol)

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


