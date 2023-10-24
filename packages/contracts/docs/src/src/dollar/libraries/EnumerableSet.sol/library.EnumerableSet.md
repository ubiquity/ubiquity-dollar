# EnumerableSet
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/7c3a0bb87e5e9b32000b3291b4e7da4b119ff3fa/src/dollar/libraries/EnumerableSet.sol)

Set implementation with enumeration functions

*Derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)*

*https://github.com/solidstate-network/solidstate-solidity/blob/master/contracts/data/EnumerableSet.sol*


## Functions
### at

Returns the value stored at position `index` in the set. O(1).
Note that there are no guarantees on the ordering of values inside the
array, and it may change when more values are added or removed.
Requirements:
- `index` must be strictly less than {length}.


```solidity
function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|Value of type `bytes32`|


### at

Returns the value stored at position `index` in the set. O(1).
Note that there are no guarantees on the ordering of values inside the
array, and it may change when more values are added or removed.
Requirements:
- `index` must be strictly less than {length}.


```solidity
function at(AddressSet storage set, uint256 index) internal view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|Value of type `address`|


### at

Returns the value stored at position `index` in the set. O(1).
Note that there are no guarantees on the ordering of values inside the
array, and it may change when more values are added or removed.
Requirements:
- `index` must be strictly less than {length}.


```solidity
function at(UintSet storage set, uint256 index) internal view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Value of type `uint256`|


### contains

Returns true if the value of type `bytes32` is in the set. O(1).


```solidity
function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool);
```

### contains

Returns true if the value of type `address` is in the set. O(1).


```solidity
function contains(AddressSet storage set, address value) internal view returns (bool);
```

### contains

Returns true if the value of type `uint256` is in the set. O(1).


```solidity
function contains(UintSet storage set, uint256 value) internal view returns (bool);
```

### indexOf

Returns index of the `value` of type `bytes32` in the `set`


```solidity
function indexOf(Bytes32Set storage set, bytes32 value) internal view returns (uint256);
```

### indexOf

Returns index of the `value` of type `address` in the `set`


```solidity
function indexOf(AddressSet storage set, address value) internal view returns (uint256);
```

### indexOf

Returns index of the `value` of type `uint256` in the `set`


```solidity
function indexOf(UintSet storage set, uint256 value) internal view returns (uint256);
```

### length

Returns the number of values in the set. O(1).


```solidity
function length(Bytes32Set storage set) internal view returns (uint256);
```

### length

Returns the number of values in the set. O(1).


```solidity
function length(AddressSet storage set) internal view returns (uint256);
```

### length

Returns the number of values in the set. O(1).


```solidity
function length(UintSet storage set) internal view returns (uint256);
```

### add

Adds a value of type `bytes32` to a set. O(1).
Returns true if the value was added to the set, that is if it was not
already present.


```solidity
function add(Bytes32Set storage set, bytes32 value) internal returns (bool);
```

### add

Adds a value of type `address` to a set. O(1).
Returns true if the value was added to the set, that is if it was not
already present.


```solidity
function add(AddressSet storage set, address value) internal returns (bool);
```

### add

Adds a value of type `uint256` to a set. O(1).
Returns true if the value was added to the set, that is if it was not
already present.


```solidity
function add(UintSet storage set, uint256 value) internal returns (bool);
```

### remove

Removes a value of type `bytes32` from a set. O(1).
Returns true if the value was removed from the set, that is if it was
present.


```solidity
function remove(Bytes32Set storage set, bytes32 value) internal returns (bool);
```

### remove

Removes a value of type `address` from a set. O(1).
Returns true if the value was removed from the set, that is if it was
present.


```solidity
function remove(AddressSet storage set, address value) internal returns (bool);
```

### remove

Removes a value of type `uint256` from a set. O(1).
Returns true if the value was removed from the set, that is if it was
present.


```solidity
function remove(UintSet storage set, uint256 value) internal returns (bool);
```

### toArray

Returns set values as an array of type `bytes32[]`


```solidity
function toArray(Bytes32Set storage set) internal view returns (bytes32[] memory);
```

### toArray

Returns set values as an array of type `address[]`


```solidity
function toArray(AddressSet storage set) internal view returns (address[] memory);
```

### toArray

Returns set values as an array of type `uint256[]`


```solidity
function toArray(UintSet storage set) internal view returns (uint256[] memory);
```

### _at

Returns the value stored at position `index` in the set. O(1).
Note that there are no guarantees on the ordering of values inside the
array, and it may change when more values are added or removed.
Requirements:
- `index` must be strictly less than {length}.


```solidity
function _at(Set storage set, uint256 index) private view returns (bytes32);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|Value of type `bytes32`|


### _contains

Returns true if the value of type `bytes32` is in the set. O(1).


```solidity
function _contains(Set storage set, bytes32 value) private view returns (bool);
```

### _indexOf

Returns index of the `value` of type `bytes32` in the `set`


```solidity
function _indexOf(Set storage set, bytes32 value) private view returns (uint256);
```

### _length

Returns the number of values in the set. O(1).


```solidity
function _length(Set storage set) private view returns (uint256);
```

### _add

Adds a value of type `bytes32` to a set. O(1).
Returns true if the value was added to the set, that is if it was not
already present.


```solidity
function _add(Set storage set, bytes32 value) private returns (bool ret);
```

### _remove

Removes a value of type `bytes32` from a set. O(1).
Returns true if the value was removed from the set, that is if it was
present.


```solidity
function _remove(Set storage set, bytes32 value) private returns (bool ret);
```

## Errors
### EnumerableSet__IndexOutOfBounds
Thrown when index does not exist


```solidity
error EnumerableSet__IndexOutOfBounds();
```

## Structs
### Set
Set struct


```solidity
struct Set {
    bytes32[] _values;
    mapping(bytes32 => uint256) _indexes;
}
```

### Bytes32Set
Bytes32Set


```solidity
struct Bytes32Set {
    Set _inner;
}
```

### AddressSet
AddressSet


```solidity
struct AddressSet {
    Set _inner;
}
```

### UintSet
UintSet


```solidity
struct UintSet {
    Set _inner;
}
```

