# DirectGovernanceFarmer
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/7c3a0bb87e5e9b32000b3291b4e7da4b119ff3fa/src/dollar/DirectGovernanceFarmer.sol)

**Inherits:**
ReentrancyGuard

Contract for simpler staking

How it works:
1. User sends stablecoins (DAI / USDC / USDT / Dollar)
2. Deposited stablecoins are added to Dollar-3CRV Curve MetaPool
3. User gets Dollar-3CRV LP tokens
4. Dollar-3CRV LP tokens are transferred to the staking contract
5. User gets a staking share id


## State Variables
### token2
USDT address


```solidity
address public immutable token2;
```


### token1
USDC address


```solidity
address public immutable token1;
```


### token0
DAI address


```solidity
address public immutable token0;
```


### ubiquity3PoolLP
Dollar-3CRV Curve MetaPool address


```solidity
address public immutable ubiquity3PoolLP;
```


### ubiquityDollar
Dollar address


```solidity
address public immutable ubiquityDollar;
```


### depositZapUbiquityDollar
Curve Deposit Zap address


```solidity
address public immutable depositZapUbiquityDollar;
```


### manager
Dollar manager address


```solidity
IUbiquityDollarManager public immutable manager;
```


## Functions
### constructor

Contract constructor


```solidity
constructor(IUbiquityDollarManager _manager, address base3Pool, address depositZap);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`_manager`|`IUbiquityDollarManager`|Dollar manager address|
|`base3Pool`|`address`|Curve TriPool address (DAI, USDC, USDT)|
|`depositZap`|`address`|Curve Deposit Zap address|


### onERC1155Received

Handles the receipt of a single ERC1155 token type. This function is
called at the end of a `safeTransferFrom` after the balance has been updated.
TODO: create updateConfig method, need to check that `operator` is authorized, `from` is Valid, `id` exists

To accept the transfer, this must return
`bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
(i.e. 0xf23a6e61, or its own function selector).


```solidity
function onERC1155Received(address, address, uint256, uint256, bytes calldata) public virtual returns (bytes4);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes4`|`bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed|


### depositSingle

Deposits a single token to staking

Stable coin (DAI / USDC / USDT / Ubiquity Dollar) => Dollar-3CRV LP => Ubiquity Staking

How it works:
1. User sends stablecoins (DAI / USDC / USDT / Dollar)
2. Deposited stablecoins are added to Dollar-3CRV Curve MetaPool
3. User gets Dollar-3CRV LP tokens
4. Dollar-3CRV LP tokens are transferred to the staking contract
5. User gets a staking share id


```solidity
function depositSingle(address token, uint256 amount, uint256 durationWeeks)
    external
    nonReentrant
    returns (uint256 stakingShareId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|Token deposited : DAI, USDC, USDT or Ubiquity Dollar|
|`amount`|`uint256`|Amount of tokens to deposit (For max: `uint256(-1)`)|
|`durationWeeks`|`uint256`|Duration in weeks tokens will be locked (1-208)|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`stakingShareId`|`uint256`|Staking share id|


### depositMulti

Deposits into Ubiquity protocol

Stable coins (DAI / USDC / USDT / Ubiquity Dollar) => uAD3CRV-f => Ubiquity StakingShare

STEP 1 : Change (DAI / USDC / USDT / Ubiquity dollar) to 3CRV at uAD3CRV MetaPool

STEP 2 : uAD3CRV-f => Ubiquity StakingShare


```solidity
function depositMulti(uint256[4] calldata tokenAmounts, uint256 durationWeeks)
    external
    nonReentrant
    returns (uint256 stakingShareId);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`tokenAmounts`|`uint256[4]`|Amount of tokens to deposit (For max: `uint256(-1)`) it MUST follow this order [Ubiquity Dollar, DAI, USDC, USDT]|
|`durationWeeks`|`uint256`|Duration in weeks tokens will be locked (1-208)|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`stakingShareId`|`uint256`|Staking share id|


### withdraw

Withdraws from Ubiquity protocol

Ubiquity StakingShare => uAD3CRV-f  => stable coin (DAI / USDC / USDT / Ubiquity Dollar)

STEP 1 : Ubiquity StakingShare  => uAD3CRV-f

STEP 2 : uAD3CRV-f => stable coin (DAI / USDC / USDT / Ubiquity Dollar)


```solidity
function withdraw(uint256 stakingShareId) external nonReentrant returns (uint256[4] memory tokenAmounts);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`stakingShareId`|`uint256`|Staking Share Id to withdraw|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`tokenAmounts`|`uint256[4]`|Array of token amounts [Ubiquity Dollar, DAI, USDC, USDT]|


### withdraw

Withdraws from Ubiquity protocol

Ubiquity StakingShare => uAD3CRV-f  => stable coin (DAI / USDC / USDT / Ubiquity Dollar)

STEP 1 : Ubiquity StakingShare  => uAD3CRV-f

STEP 2 : uAD3CRV-f => stable coin (DAI / USDC / USDT / Ubiquity Dollar)


```solidity
function withdraw(uint256 stakingShareId, address token) external nonReentrant returns (uint256 tokenAmount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`stakingShareId`|`uint256`|Staking Share Id to withdraw|
|`token`|`address`|Token to withdraw to : DAI, USDC, USDT, 3CRV or Ubiquity Dollar|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`tokenAmount`|`uint256`|Amount of token withdrawn|


### isIdIncluded

Checks whether `id` exists in `idList[]`


```solidity
function isIdIncluded(uint256[] memory idList, uint256 id) internal pure returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`idList`|`uint256[]`|Array to search in|
|`id`|`uint256`|Value to search in `idList`|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|Whether `id` exists in `idList[]`|


### isMetaPoolCoin

Checks that `token` is one of the underlying MetaPool tokens or stablecoin from MetaPool


```solidity
function isMetaPoolCoin(address token) public view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`token`|`address`|Token address to check|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|Whether `token` is one of the underlying MetaPool tokens or stablecoin from MetaPool|


## Events
### DepositSingle
Emitted when user deposits a single token


```solidity
event DepositSingle(
    address indexed sender, address token, uint256 amount, uint256 durationWeeks, uint256 stakingShareId
);
```

### DepositMulti
Emitted when user deposits multiple tokens


```solidity
event DepositMulti(address indexed sender, uint256[4] amounts, uint256 durationWeeks, uint256 stakingShareId);
```

### Withdraw
Emitted when user withdraws a single token


```solidity
event Withdraw(address indexed sender, uint256 stakingShareId, address token, uint256 amount);
```

### WithdrawAll
Emitted when user withdraws multiple tokens


```solidity
event WithdrawAll(address indexed sender, uint256 stakingShareId, uint256[4] amounts);
```

