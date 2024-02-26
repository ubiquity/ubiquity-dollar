# MockERC20
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/06f2fdfc8852ea0bb7a36def890d6742ea2373df/src/dollar/mocks/MockERC20.sol)

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

