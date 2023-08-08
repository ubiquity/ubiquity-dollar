# MockCreditToken
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/c4890e02aea7bcfd69c21e5e480e0b3a22e5e740/src/dollar/mocks/MockCreditToken.sol)

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

