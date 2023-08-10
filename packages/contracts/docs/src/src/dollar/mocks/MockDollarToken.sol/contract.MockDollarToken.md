# MockDollarToken
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/3bd8ebfb9c040c43bc7387d834825102cd1e7687/src/dollar/mocks/MockDollarToken.sol)

**Inherits:**
ERC20


## Functions
### constructor


```solidity
constructor(uint256 initialSupply) ERC20("ubiquityDollar", "uAD");
```

### burn


```solidity
function burn(address account, uint256 amount) public;
```

### burnFrom


```solidity
function burnFrom(address account, uint256 amount) public;
```

### mint


```solidity
function mint(address account, uint256 amount) public;
```

