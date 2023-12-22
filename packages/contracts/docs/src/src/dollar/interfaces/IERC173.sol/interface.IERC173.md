# IERC173
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/40df6b48aeb8f52a1ca16fc758a5459764bee6c2/src/dollar/interfaces/IERC173.sol)

ERC-173 Contract Ownership Standard

*ERC-165 identifier for this interface is 0x7f5828d0*


## Functions
### owner

Returns owner's address


```solidity
function owner() external view returns (address owner_);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`owner_`|`address`|Owner address|


### transferOwnership

Sets contract's owner to a new address

*Set _newOwner to address(0) to renounce any ownership*


```solidity
function transferOwnership(address _newOwner) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_newOwner`|`address`|The address of the new owner of the contract|


## Events
### OwnershipTransferred
Emits when ownership of a contract changes


```solidity
event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
```

