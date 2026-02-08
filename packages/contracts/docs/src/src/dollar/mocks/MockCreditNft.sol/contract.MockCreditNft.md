# MockCreditNft
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/9b081c9a3593a6c50107cbbe15494a939de0a708/src/dollar/mocks/MockCreditNft.sol)

**Inherits:**
ERC1155


## State Variables
### _totalOutstandingDebt

```solidity
uint256 private _totalOutstandingDebt;
```


### checkPoint

```solidity
uint256 public checkPoint;
```


### _balances

```solidity
mapping(address => mapping(uint256 => uint256)) _balances;
```


## Functions
### constructor


```solidity
constructor(uint256 totalDebt) ERC1155("URI");
```

### setTotalOutstandingDebt


```solidity
function setTotalOutstandingDebt(uint256 totalDebt) public;
```

### getTotalOutstandingDebt


```solidity
function getTotalOutstandingDebt() public view returns (uint256);
```

### updateTotalDebt


```solidity
function updateTotalDebt() public;
```

### mintCreditNft


```solidity
function mintCreditNft(address receiver, uint256 amount, uint256 expiryBlockNumber) public;
```

### balanceOf


```solidity
function balanceOf(address receiver, uint256 id) public view override returns (uint256);
```

### burnCreditNft


```solidity
function burnCreditNft(address creditNftOwner, uint256 amount, uint256 expiryBlockNumber) public;
```

## Events
### MintedCreditNft

```solidity
event MintedCreditNft(address recipient, uint256 expiryBlock, uint256 amount);
```

### BurnedCreditNft

```solidity
event BurnedCreditNft(address creditNftHolder, uint256 expiryBlock, uint256 amount);
```

