# LibAppStorage
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/b3082cd78c54c73c487f0fe24d8f9b24a6ac0c9e/src/dollar/libraries/LibAppStorage.sol)

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


