# MockERC20
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/4c13028f071ee182255e5194c6edfe61ae2c69b2/src/dollar/mocks/MockERC20.sol)

**Inherits:**
ERC20


## State Variables
### __decimals

```solidity
uint8 internal __decimals;
```


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

### decimals


```solidity
function decimals() public view virtual override returns (uint8);
```

