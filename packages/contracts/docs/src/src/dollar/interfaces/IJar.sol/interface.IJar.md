# IJar
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/7c3a0bb87e5e9b32000b3291b4e7da4b119ff3fa/src/dollar/interfaces/IJar.sol)

**Inherits:**
IERC20

IJar interface


## Functions
### claimInsurance

Transfers insurance to controller


```solidity
function claimInsurance() external;
```

### depositAll

Deposits the whole user balance


```solidity
function depositAll() external;
```

### deposit

Deposits a specified amount of tokens


```solidity
function deposit(uint256) external;
```

### withdrawAll

Withdraws all tokens


```solidity
function withdrawAll() external;
```

### withdraw

Withdraws a specified amount of tokens


```solidity
function withdraw(uint256) external;
```

### earn

Run strategy


```solidity
function earn() external;
```

### token

Returns token address


```solidity
function token() external view returns (address);
```

### reward

Returns reward amount


```solidity
function reward() external view returns (address);
```

### getRatio

Returns ratio


```solidity
function getRatio() external view returns (uint256);
```

### balance

Returns token balance


```solidity
function balance() external view returns (uint256);
```

### decimals

Returns token decimals


```solidity
function decimals() external view returns (uint8);
```

