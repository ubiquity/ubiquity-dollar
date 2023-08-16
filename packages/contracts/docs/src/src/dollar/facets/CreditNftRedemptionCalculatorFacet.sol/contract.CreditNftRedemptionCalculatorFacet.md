# CreditNftRedemptionCalculatorFacet
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/66e97ec8763806fd714a23d6e8eaecfdd8d08108/src/dollar/facets/CreditNftRedemptionCalculatorFacet.sol)

**Inherits:**
[ICreditNftRedemptionCalculator](/src/dollar/interfaces/ICreditNftRedemptionCalculator.sol/interface.ICreditNftRedemptionCalculator.md)

Contract facet for calculating amount of Credit NFTs to mint on Dollars burn


## Functions
### getCreditNftAmount

Returns Credit NFT amount minted for `dollarsToBurn` amount of Dollars to burn


```solidity
function getCreditNftAmount(uint256 dollarsToBurn) external view override returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`dollarsToBurn`|`uint256`|Amount of Dollars to burn|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Amount of Credit NFTs to mint|


