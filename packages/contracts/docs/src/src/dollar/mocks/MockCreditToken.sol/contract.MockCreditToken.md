# MockCreditToken
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/ccc689b8b816039996240d21714a491a27963d57/packages/contracts/src/dollar/mocks/MockCreditToken.sol)

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

