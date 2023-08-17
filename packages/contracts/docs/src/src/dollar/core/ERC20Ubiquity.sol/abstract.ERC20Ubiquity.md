# ERC20Ubiquity
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/d47ba67ecbe94bc364a206fbde6b184405f4ec97/src/dollar/core/ERC20Ubiquity.sol)

**Inherits:**
ERC20Permit, ERC20Pausable, [IERC20Ubiquity](/src/dollar/interfaces/IERC20Ubiquity.sol/interface.IERC20Ubiquity.md)

Base contract for Ubiquity ERC20 tokens (Dollar, Credit, Governance)

ERC20 with:
- ERC20 minter, burner and pauser
- draft-ERC20 permit
- Ubiquity Manager access control


## State Variables
### _symbol
Token symbol


```solidity
string private _symbol;
```


### accessControl
Access control interface


```solidity
IAccessControl public accessControl;
```


## Functions
### onlyPauser

Modifier checks that the method is called by a user with the "pauser" role


```solidity
modifier onlyPauser();
```

### onlyAdmin

Modifier checks that the method is called by a user with the "admin" role


```solidity
modifier onlyAdmin();
```

### constructor

Contract constructor


```solidity
constructor(address _manager, string memory name_, string memory symbol_) ERC20(name_, symbol_) ERC20Permit(name_);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_manager`|`address`|Access control address|
|`name_`|`string`|Token name|
|`symbol_`|`string`|Token symbol|


### setSymbol

Updates token symbol


```solidity
function setSymbol(string memory newSymbol) external onlyAdmin;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newSymbol`|`string`|New token symbol name|


### symbol

Returns token symbol name


```solidity
function symbol() public view virtual override returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|Token symbol name|


### getManager

Returns access control address


```solidity
function getManager() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|Access control address|


### setManager

Sets access control address


```solidity
function setManager(address _manager) external onlyAdmin;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_manager`|`address`|New access control address|


### pause

Pauses all token transfers


```solidity
function pause() public onlyPauser;
```

### unpause

Unpauses all token transfers


```solidity
function unpause() public onlyPauser;
```

### burn

Destroys `amount` tokens from the caller


```solidity
function burn(uint256 amount) public virtual whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|Amount of tokens to destroy|


### burnFrom

Destroys `amount` tokens from `account`, deducting from the caller's
allowance

Requirements:
- the caller must have allowance for `account`'s tokens of at least `amount`


```solidity
function burnFrom(address account, uint256 amount) public virtual;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|Address to burn tokens from|
|`amount`|`uint256`|Amount of tokens to burn|


### _beforeTokenTransfer

Hook that is called before any transfer of tokens. This includes
minting and burning.
Calling conditions:
- when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
will be transferred to `to`.
- when `from` is zero, `amount` tokens will be minted for `to`.
- when `to` is zero, `amount` of ``from``'s tokens will be burned.
- `from` and `to` are never both zero.


```solidity
function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal
    virtual
    override(ERC20, ERC20Pausable);
```

### _transfer

Moves `amount` of tokens from `from` to `to`.
This internal function is equivalent to `transfer`, and can be used to
e.g. implement automatic token fees, slashing mechanisms, etc.
Emits a `Transfer` event.
Requirements:
- `from` cannot be the zero address.
- `to` cannot be the zero address.
- `from` must have a balance of at least `amount`.


```solidity
function _transfer(address sender, address recipient, uint256 amount) internal virtual override whenNotPaused;
```

