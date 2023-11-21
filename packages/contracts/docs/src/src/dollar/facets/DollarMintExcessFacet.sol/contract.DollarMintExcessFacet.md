# DollarMintExcessFacet
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/f091cd4ba5dd663d35be00c9fd51b8d69e991a45/src/dollar/facets/DollarMintExcessFacet.sol)

**Inherits:**
[IDollarMintExcess](/src/dollar/interfaces/IDollarMintExcess.sol/interface.IDollarMintExcess.md)

Contract facet for distributing excess Dollars when `mintClaimableDollars()` is called

Excess Dollars are distributed this way:
- 50% goes to the treasury address
- 10% goes for burning Dollar-Governance LP tokens in a DEX pool
- 40% goes to the Staking contract


## Functions
### distributeDollars

Distributes excess Dollars:
- 50% goes to the treasury address
- 10% goes for burning Dollar-Governance LP tokens in a DEX pool
- 40% goes to the Staking contract


```solidity
function distributeDollars() external override;
```

