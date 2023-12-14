# LibCreditNftRedemptionCalculator
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/b7267f12c687aa106d733f5496a8a4b4e266c3ec/src/dollar/libraries/LibCreditNftRedemptionCalculator.sol)

Library for calculating amount of Credit NFTs to mint on Dollars burn


## Functions
### getCreditNftAmount

Returns Credit NFT amount minted for `dollarsToBurn` amount of Dollars to burn


```solidity
function getCreditNftAmount(uint256 dollarsToBurn) internal view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`dollarsToBurn`|`uint256`|Amount of Dollars to burn|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Amount of Credit NFTs to mint|


