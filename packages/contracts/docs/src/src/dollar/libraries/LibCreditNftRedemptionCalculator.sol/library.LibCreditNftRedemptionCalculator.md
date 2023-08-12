# LibCreditNftRedemptionCalculator
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/9b081c9a3593a6c50107cbbe15494a939de0a708/src/dollar/libraries/LibCreditNftRedemptionCalculator.sol)

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


