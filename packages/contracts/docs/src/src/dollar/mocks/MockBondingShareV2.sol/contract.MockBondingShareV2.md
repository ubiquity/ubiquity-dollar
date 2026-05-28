# MockBondingShareV2
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/7de99efbd24b43cb89b03b0f63c9241a23e6a660/src/dollar/mocks/MockBondingShareV2.sol)

**Inherits:**
ERC1155, ERC1155Burnable, ERC1155Pausable


## State Variables
### manager

```solidity
IUbiquityDollarManager public manager;
```


### _holderBalances

```solidity
mapping(address => uint256[]) private _holderBalances;
```


### _bonds

```solidity
mapping(uint256 => Bond) private _bonds;
```


### _totalLP

```solidity
uint256 private _totalLP;
```


### _totalSupply

```solidity
uint256 private _totalSupply;
```


## Functions
### onlyMinter


```solidity
modifier onlyMinter();
```

### onlyBurner


```solidity
modifier onlyBurner();
```

### onlyPauser


```solidity
modifier onlyPauser();
```

### constructor

*constructor*


```solidity
constructor(address _manager, string memory uri) ERC1155(uri);
```

### updateBond

*update bond LP amount , LP rewards debt and end block.*


```solidity
function updateBond(uint256 _bondId, uint256 _lpAmount, uint256 _lpRewardDebt, uint256 _endBlock)
    external
    onlyMinter
    whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_bondId`|`uint256`|bonding share id|
|`_lpAmount`|`uint256`|amount of LP token deposited|
|`_lpRewardDebt`|`uint256`|amount of excess LP token inside the bonding contract|
|`_endBlock`|`uint256`|end locking period block number|


### mint


```solidity
function mint(address to, uint256 lpDeposited, uint256 lpRewardDebt, uint256 endBlock)
    public
    virtual
    onlyMinter
    whenNotPaused
    returns (uint256 id);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|owner address|
|`lpDeposited`|`uint256`|amount of LP token deposited|
|`lpRewardDebt`|`uint256`|amount of excess LP token inside the bonding contract|
|`endBlock`|`uint256`|block number when the locking period ends|


### pause

*Pauses all token transfers.
See {ERC1155Pausable} and {Pausable-_pause}.*


```solidity
function pause() public virtual onlyPauser;
```

### unpause

*Unpauses all token transfers.
See {ERC1155Pausable} and {Pausable-_unpause}.*


```solidity
function unpause() public virtual onlyPauser;
```

### safeTransferFrom

*See {IERC1155-safeTransferFrom}.*


```solidity
function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes memory data)
    public
    override
    whenNotPaused;
```

### safeBatchTransferFrom

*See {IERC1155-safeBatchTransferFrom}.*


```solidity
function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
) public virtual override whenNotPaused;
```

### totalSupply

*Total amount of tokens  .*


```solidity
function totalSupply() public view virtual returns (uint256);
```

### totalLP

*Total amount of LP tokens deposited.*


```solidity
function totalLP() public view virtual returns (uint256);
```

### getBond

*return bond details.*


```solidity
function getBond(uint256 id) public view returns (Bond memory);
```

### holderTokens

*array of token Id held by the msg.sender.*


```solidity
function holderTokens(address holder) public view returns (uint256[] memory);
```

### _burn


```solidity
function _burn(address account, uint256 id, uint256 amount) internal virtual override whenNotPaused;
```

### _burnBatch


```solidity
function _burnBatch(address account, uint256[] memory ids, uint256[] memory amounts)
    internal
    virtual
    override
    whenNotPaused;
```

### _beforeTokenTransfer


```solidity
function _beforeTokenTransfer(
    address operator,
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
) internal virtual override(ERC1155, ERC1155Pausable);
```

## Structs
### Bond

```solidity
struct Bond {
    address minter;
    uint256 lpFirstDeposited;
    uint256 creationBlock;
    uint256 lpRewardDebt;
    uint256 endBlock;
    uint256 lpAmount;
}
```

