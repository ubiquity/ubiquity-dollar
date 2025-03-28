# BondingShare
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/109cec7a9dabc6e0b7a4678e6dc13e4441471a22/src/dollar/mocks/MockShareV1.sol)

**Inherits:**
[StakingShare](/src/dollar/core/StakingShare.sol/contract.StakingShare.md)


## Functions
### constructor


```solidity
constructor();
```

### initialize


```solidity
function initialize(address _manager, string memory uri) public override initializer;
```

### hasUpgraded


```solidity
function hasUpgraded() public pure virtual returns (bool);
```

### getVersion


```solidity
function getVersion() public view virtual returns (uint8);
```

### getImpl


```solidity
function getImpl() public view virtual returns (address);
```

