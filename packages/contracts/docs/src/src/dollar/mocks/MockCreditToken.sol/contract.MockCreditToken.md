# MockCreditToken
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/7de99efbd24b43cb89b03b0f63c9241a23e6a660/src/dollar/mocks/MockCreditToken.sol)

**Inherits:**
ERC20


## Functions
### constructor


```solidity
constructor(uint256 initialSupply) ERC20("Ubiquity Auto Redeem", "uAR");
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

### raiseCapital


```solidity
function raiseCapital(uint256 amount) external;
```

