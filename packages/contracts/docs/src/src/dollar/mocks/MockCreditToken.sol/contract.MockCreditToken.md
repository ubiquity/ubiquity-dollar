# MockCreditToken
[Git Source](https://github.com/rndquu/ubiquity-dollar/blob/acaf5012d59fae725859d662b4b531abaa7ec8f5/src/dollar/mocks/MockCreditToken.sol)

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

