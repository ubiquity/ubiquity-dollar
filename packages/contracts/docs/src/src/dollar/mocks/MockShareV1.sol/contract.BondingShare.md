# BondingShare
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/b7267f12c687aa106d733f5496a8a4b4e266c3ec/src/dollar/mocks/MockShareV1.sol)

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

