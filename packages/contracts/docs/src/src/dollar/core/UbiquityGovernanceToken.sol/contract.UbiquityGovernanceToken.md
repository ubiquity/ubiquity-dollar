# UbiquityGovernanceToken
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/9b081c9a3593a6c50107cbbe15494a939de0a708/src/dollar/core/UbiquityGovernanceToken.sol)

**Inherits:**
[ERC20Ubiquity](/src/dollar/core/ERC20Ubiquity.sol/abstract.ERC20Ubiquity.md)

Ubiquity Governance token contract


## Functions
### constructor

Contract constructor


```solidity
constructor(address _manager) ERC20Ubiquity(_manager, "Ubiquity", "UBQ");
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_manager`|`address`|Access control address|


### onlyGovernanceMinter

Modifier checks that the method is called by a user with the "Governance minter" role


```solidity
modifier onlyGovernanceMinter();
```

### onlyGovernanceBurner

Modifier checks that the method is called by a user with the "Governance burner" role


```solidity
modifier onlyGovernanceBurner();
```

### burnFrom

Burns Governance tokens from the `account` address


```solidity
function burnFrom(address account, uint256 amount) public override onlyGovernanceBurner whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|Address to burn tokens from|
|`amount`|`uint256`|Amount of tokens to burn|


### mint

Mints Governance tokens to the `to` address


```solidity
function mint(address to, uint256 amount) public override onlyGovernanceMinter whenNotPaused;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|Address to mint tokens to|
|`amount`|`uint256`|Amount of tokens to mint|


