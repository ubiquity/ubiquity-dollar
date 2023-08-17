# DollarMintCalculatorFacet
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/d47ba67ecbe94bc364a206fbde6b184405f4ec97/src/dollar/facets/DollarMintCalculatorFacet.sol)

**Inherits:**
[IDollarMintCalculator](/src/dollar/interfaces/IDollarMintCalculator.sol/interface.IDollarMintCalculator.md)

Calculates amount of Dollars ready to be minted when TWAP price (i.e. Dollar price) > 1$


## Functions
### getDollarsToMint

Returns amount of Dollars to be minted based on formula `(TWAP_PRICE - 1) * DOLLAR_TOTAL_SUPPLY`


```solidity
function getDollarsToMint() external view override returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Amount of Dollars to be minted|


