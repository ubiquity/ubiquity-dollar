# LibDollarMintCalculator
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/40df6b48aeb8f52a1ca16fc758a5459764bee6c2/src/dollar/libraries/LibDollarMintCalculator.sol)

Calculates amount of Dollars ready to be minted when TWAP price (i.e. Dollar price) > 1$


## Functions
### getDollarsToMint

Returns amount of Dollars to be minted based on formula `(TWAP_PRICE - 1) * DOLLAR_TOTAL_SUPPLY`


```solidity
function getDollarsToMint() internal view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Amount of Dollars to be minted|


