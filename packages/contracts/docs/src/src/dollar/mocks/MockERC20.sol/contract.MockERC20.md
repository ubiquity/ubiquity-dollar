# MockERC20
[Git Source](https://github.com/rndquu/ubiquity-dollar/blob/acaf5012d59fae725859d662b4b531abaa7ec8f5/src/dollar/mocks/MockERC20.sol)

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

