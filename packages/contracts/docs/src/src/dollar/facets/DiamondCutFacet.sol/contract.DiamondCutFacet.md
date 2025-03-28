# DiamondCutFacet
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/109cec7a9dabc6e0b7a4678e6dc13e4441471a22/src/dollar/facets/DiamondCutFacet.sol)

**Inherits:**
[IDiamondCut](/src/dollar/interfaces/IDiamondCut.sol/interface.IDiamondCut.md)

Facet used for diamond selector modifications

*Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
The loupe functions are required by the EIP2535 Diamonds standard.*


## Functions
### diamondCut

Add/replace/remove any number of functions and optionally execute a function with delegatecall

*`_calldata` is executed with delegatecall on `_init`*


```solidity
function diamondCut(FacetCut[] calldata _diamondCut, address _init, bytes calldata _calldata) external override;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_diamondCut`|`FacetCut[]`|Contains the facet addresses and function selectors|
|`_init`|`address`|The address of the contract or facet to execute _calldata|
|`_calldata`|`bytes`|A function call, including function selector and arguments|


