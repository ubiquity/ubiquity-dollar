# MockERC20
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/109cec7a9dabc6e0b7a4678e6dc13e4441471a22/src/dollar/mocks/MockERC20.sol)

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

