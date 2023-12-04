# BondingShare
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/bc36823136700d0422c14fd5ae111920580c10d7/src/dollar/mocks/MockShareV1.sol)

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

