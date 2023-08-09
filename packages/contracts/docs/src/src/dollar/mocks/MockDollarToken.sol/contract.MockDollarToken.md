# MockDollarToken
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/45e53ee37d9a8440a7cebde4e1d8182112836cab/src/dollar/mocks/MockDollarToken.sol)

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

