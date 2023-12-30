# MockERC20
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/cbd28a4612a3e634eb46789c9d7030bc45955983/src/dollar/mocks/MockERC20.sol)

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

