# UbiquityDollarToken
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/7c3a0bb87e5e9b32000b3291b4e7da4b119ff3fa/src/dollar/core/UbiquityDollarToken.sol)

**Inherits:**
[ERC20Ubiquity](/src/dollar/core/ERC20Ubiquity.sol/abstract.ERC20Ubiquity.md)

Ubiquity Dollar token contract


## State Variables
### incentiveContract
Mapping of account and incentive contract address

*Address is 0 if there is no incentive contract for the account*


```solidity
mapping(address => address) public incentiveContract;
```


## Functions
### constructor

Ensures initialize cannot be called on the implementation contract


```solidity
constructor();
```

### initialize

Initializes the contract


```solidity
function initialize(address _manager) public initializer;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_manager`|`address`|Address of the Ubiquity Manager|


### onlyDollarMinter

Modifier checks that the method is called by a user with the "Dollar minter" role


```solidity
modifier onlyDollarMinter();
```

### onlyDollarBurner

Modifier checks that the method is called by a user with the "Dollar burner" role


```solidity
modifier onlyDollarBurner();
```

### setIncentiveContract

Sets `incentive` contract for `account`

Incentive contracts are applied on Dollar transfers:
- EOA => contract
- contract => EOA
- contract => contract
- any transfer global incentive


```solidity
function setIncentiveContract(address account, address incentive) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|Account to incentivize|
|`incentive`|`address`|Incentive contract address|


### _checkAndApplyIncentives

Applies incentives on Dollar transfers


```solidity
function _checkAndApplyIncentives(address sender, address recipient, uint256 amount) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`sender`|`address`|Sender address|
|`recipient`|`address`|Recipient address|
|`amount`|`uint256`|Dollar token transfer amount|


### _transfer

Moves `amount` of tokens from `from` to `to` and applies incentives.
This internal function is equivalent to `transfer`, and can be used to
e.g. implement automatic token fees, slashing mechanisms, etc.
Emits a `Transfer` event.
Requirements:
- `from` cannot be the zero address.
- `to` cannot be the zero address.
- `from` must have a balance of at least `amount`.


```solidity
function _transfer(address sender, address recipient, uint256 amount) internal override;
```

### burnFrom

Burns Dollars from the `account` address


```solidity
function burnFrom(address account, uint256 amount) public override onlyDollarBurner whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|Address to burn tokens from|
|`amount`|`uint256`|Amount of tokens to burn|


### mint

Mints Dollars to the `to` address


```solidity
function mint(address to, uint256 amount) public onlyDollarMinter whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|Address to mint tokens to|
|`amount`|`uint256`|Amount of tokens to mint|


### _authorizeUpgrade

Allows an admin to upgrade to another implementation contract


```solidity
function _authorizeUpgrade(address newImplementation) internal override onlyAdmin;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newImplementation`|`address`|Address of the new implementation contract|


## Events
### IncentiveContractUpdate
Emitted on setting an incentive contract for an account


```solidity
event IncentiveContractUpdate(address indexed _incentivized, address indexed _incentiveContract);
```

