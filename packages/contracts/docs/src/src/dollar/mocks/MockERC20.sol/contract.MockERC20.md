# MockERC20
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/c016c6dc0daa0d788a6f4e197f9b9468d8d2c907/src/dollar/mocks/MockERC20.sol)

**Inherits:**
ERC20


## Functions
### constructor


```solidity
constructor(string memory _name, string memory _symbol, uint8 _decimals) ERC20(_name, _symbol);
```

### mint


```solidity
function mint(address to, uint256 value) public virtual;
```

### burn


```solidity
function burn(address from, uint256 value) public virtual;
```

