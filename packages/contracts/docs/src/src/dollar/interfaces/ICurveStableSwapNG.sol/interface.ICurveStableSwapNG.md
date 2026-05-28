# ICurveStableSwapNG
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/b3082cd78c54c73c487f0fe24d8f9b24a6ac0c9e/src/dollar/interfaces/ICurveStableSwapNG.sol)

**Inherits:**
[ICurveStableSwapMetaNG](/src/dollar/interfaces/ICurveStableSwapMetaNG.sol/interface.ICurveStableSwapMetaNG.md)

Curve's interface for plain pool which contains only USD pegged assets


## Functions
### add_liquidity


```solidity
function add_liquidity(uint256[] memory _amounts, uint256 _min_mint_amount, address _receiver)
    external
    returns (uint256);
```

