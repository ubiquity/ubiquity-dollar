# LibUbiquityPool
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/cbd28a4612a3e634eb46789c9d7030bc45955983/src/dollar/libraries/LibUbiquityPool.sol)

Ubiquity pool library

Allows users to:
- deposit collateral in exchange for Ubiquity Dollars
- redeem Ubiquity Dollars in exchange for the earlier provided collateral


## State Variables
### UBIQUITY_POOL_STORAGE_POSITION
Storage slot used to store data for this library


```solidity
bytes32 constant UBIQUITY_POOL_STORAGE_POSITION =
    bytes32(uint256(keccak256("ubiquity.contracts.ubiquity.pool.storage")) - 1);
```


## Functions
### ubiquityPoolStorage

Returns struct used as a storage for this library


```solidity
function ubiquityPoolStorage() internal pure returns (UbiquityPoolStorage storage uPoolStorage);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`uPoolStorage`|`UbiquityPoolStorage`|Struct used as a storage|


### collateralEnabled

Checks whether collateral token is enabled (i.e. mintable and redeemable)


```solidity
modifier collateralEnabled(uint256 collateralIndex);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralIndex`|`uint256`|Collateral token index|


### onlyAmoMinter

Checks whether a caller is the AMO minter address


```solidity
modifier onlyAmoMinter();
```

### allCollaterals

Returns all collateral addresses


```solidity
function allCollaterals() internal view returns (address[] memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address[]`|All collateral addresses|


### collateralInformation

Returns collateral information


```solidity
function collateralInformation(address collateralAddress)
    internal
    view
    returns (CollateralInformation memory returnData);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralAddress`|`address`|Address of the collateral token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`returnData`|`CollateralInformation`|Collateral info|


### collateralUsdBalance

Returns USD value of all collateral tokens held in the pool, in E18


```solidity
function collateralUsdBalance() internal view returns (uint256 balanceTally);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`balanceTally`|`uint256`|USD value of all collateral tokens|


### freeCollateralBalance

Returns free collateral balance (i.e. that can be borrowed by AMO minters)


```solidity
function freeCollateralBalance(uint256 collateralIndex) internal view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralIndex`|`uint256`|collateral token index|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Amount of free collateral|


### getDollarInCollateral

Returns Dollar value in collateral tokens


```solidity
function getDollarInCollateral(uint256 collateralIndex, uint256 dollarAmount) internal view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralIndex`|`uint256`|collateral token index|
|`dollarAmount`|`uint256`|Amount of Dollars|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Value in collateral tokens|


### getDollarPriceUsd

Returns Ubiquity Dollar token USD price (1e6 precision) from Curve Metapool (Ubiquity Dollar, Curve Tri-Pool LP)


```solidity
function getDollarPriceUsd() internal view returns (uint256 dollarPriceUsd);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`dollarPriceUsd`|`uint256`|USD price of Ubiquity Dollar|


### mintDollar

Mints Dollars in exchange for collateral tokens


```solidity
function mintDollar(uint256 collateralIndex, uint256 dollarAmount, uint256 dollarOutMin, uint256 maxCollateralIn)
    internal
    collateralEnabled(collateralIndex)
    returns (uint256 totalDollarMint, uint256 collateralNeeded);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralIndex`|`uint256`|Collateral token index|
|`dollarAmount`|`uint256`|Amount of dollars to mint|
|`dollarOutMin`|`uint256`|Min amount of dollars to mint (slippage protection)|
|`maxCollateralIn`|`uint256`|Max amount of collateral to send (slippage protection)|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`totalDollarMint`|`uint256`|Amount of Dollars minted|
|`collateralNeeded`|`uint256`|Amount of collateral sent to the pool|


### redeemDollar

Burns redeemable Ubiquity Dollars and sends back 1 USD of collateral token for every 1 Ubiquity Dollar burned

*Redeem process is split in two steps:*

*1. `redeemDollar()`*

*2. `collectRedemption()`*

*This is done in order to prevent someone using a flash loan of a collateral token to mint, redeem, and collect in a single transaction/block*


```solidity
function redeemDollar(uint256 collateralIndex, uint256 dollarAmount, uint256 collateralOutMin)
    internal
    collateralEnabled(collateralIndex)
    returns (uint256 collateralOut);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralIndex`|`uint256`|Collateral token index being withdrawn|
|`dollarAmount`|`uint256`|Amount of Ubiquity Dollars being burned|
|`collateralOutMin`|`uint256`|Minimum amount of collateral tokens that'll be withdrawn, used to set acceptable slippage|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`collateralOut`|`uint256`|Amount of collateral tokens ready for redemption|


### collectRedemption

Used to collect collateral tokens after redeeming/burning Ubiquity Dollars

*Redeem process is split in two steps:*

*1. `redeemDollar()`*

*2. `collectRedemption()`*

*This is done in order to prevent someone using a flash loan of a collateral token to mint, redeem, and collect in a single transaction/block*


```solidity
function collectRedemption(uint256 collateralIndex) internal returns (uint256 collateralAmount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralIndex`|`uint256`|Collateral token index being collected|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`collateralAmount`|`uint256`|Amount of collateral tokens redeemed|


### updateChainLinkCollateralPrice

Updates collateral token price in USD from ChainLink price feed


```solidity
function updateChainLinkCollateralPrice(uint256 collateralIndex) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralIndex`|`uint256`|Collateral token index|


### amoMinterBorrow

Allows AMO minters to borrow collateral to make yield in external
protocols like Compound, Curve, erc...

*Bypasses the gassy mint->redeem cycle for AMOs to borrow collateral*


```solidity
function amoMinterBorrow(uint256 collateralAmount) internal onlyAmoMinter;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralAmount`|`uint256`|Amount of collateral to borrow|


### addAmoMinter

Adds a new AMO minter


```solidity
function addAmoMinter(address amoMinterAddress) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amoMinterAddress`|`address`|AMO minter address|


### addCollateralToken

Adds a new collateral token


```solidity
function addCollateralToken(address collateralAddress, address chainLinkPriceFeedAddress, uint256 poolCeiling)
    internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralAddress`|`address`|Collateral token address|
|`chainLinkPriceFeedAddress`|`address`|Chainlink's price feed address|
|`poolCeiling`|`uint256`|Max amount of available tokens for collateral|


### removeAmoMinter

Removes AMO minter


```solidity
function removeAmoMinter(address amoMinterAddress) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amoMinterAddress`|`address`|AMO minter address to remove|


### setCollateralChainLinkPriceFeed

Sets collateral ChainLink price feed params


```solidity
function setCollateralChainLinkPriceFeed(
    address collateralAddress,
    address chainLinkPriceFeedAddress,
    uint256 stalenessThreshold
) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralAddress`|`address`|Collateral token address|
|`chainLinkPriceFeedAddress`|`address`|ChainLink price feed address|
|`stalenessThreshold`|`uint256`|Threshold in seconds when chainlink answer should be considered stale|


### setFees

Sets mint and redeem fees, 1_000_000 = 100%


```solidity
function setFees(uint256 collateralIndex, uint256 newMintFee, uint256 newRedeemFee) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralIndex`|`uint256`|Collateral token index|
|`newMintFee`|`uint256`|New mint fee|
|`newRedeemFee`|`uint256`|New redeem fee|


### setPoolCeiling

Sets max amount of collateral for a particular collateral token


```solidity
function setPoolCeiling(uint256 collateralIndex, uint256 newCeiling) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralIndex`|`uint256`|Collateral token index|
|`newCeiling`|`uint256`|Max amount of collateral|


### setPriceThresholds

Sets mint and redeem price thresholds, 1_000_000 = $1.00


```solidity
function setPriceThresholds(uint256 newMintPriceThreshold, uint256 newRedeemPriceThreshold) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newMintPriceThreshold`|`uint256`|New mint price threshold|
|`newRedeemPriceThreshold`|`uint256`|New redeem price threshold|


### setRedemptionDelayBlocks

Sets a redemption delay in blocks

*Redeeming is split in 2 actions:*

*1. `redeemDollar()`*

*2. `collectRedemption()`*

*`newRedemptionDelayBlocks` sets number of blocks that should be mined after which user can call `collectRedemption()`*


```solidity
function setRedemptionDelayBlocks(uint256 newRedemptionDelayBlocks) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newRedemptionDelayBlocks`|`uint256`|Redemption delay in blocks|


### toggleCollateral

Toggles (i.e. enables/disables) a particular collateral token


```solidity
function toggleCollateral(uint256 collateralIndex) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralIndex`|`uint256`|Collateral token index|


### toggleMintRedeemBorrow

Toggles pause for mint/redeem/borrow methods


```solidity
function toggleMintRedeemBorrow(uint256 collateralIndex, uint8 toggleIndex) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralIndex`|`uint256`|Collateral token index|
|`toggleIndex`|`uint8`|Method index. 0 - toggle mint pause, 1 - toggle redeem pause, 2 - toggle borrow by AMO pause|


## Events
### AmoMinterAdded
Emitted when new AMO minter is added


```solidity
event AmoMinterAdded(address amoMinterAddress);
```

### AmoMinterRemoved
Emitted when AMO minter is removed


```solidity
event AmoMinterRemoved(address amoMinterAddress);
```

### CollateralPriceFeedSet
Emitted on setting a chainlink's collateral price feed params


```solidity
event CollateralPriceFeedSet(uint256 collateralIndex, address priceFeedAddress, uint256 stalenessThreshold);
```

### CollateralPriceSet
Emitted on setting a collateral price


```solidity
event CollateralPriceSet(uint256 collateralIndex, uint256 newPrice);
```

### CollateralToggled
Emitted on enabling/disabling a particular collateral token


```solidity
event CollateralToggled(uint256 collateralIndex, bool newState);
```

### FeesSet
Emitted when fees are updated


```solidity
event FeesSet(uint256 collateralIndex, uint256 newMintFee, uint256 newRedeemFee);
```

### MintRedeemBorrowToggled
Emitted on toggling pause for mint/redeem/borrow


```solidity
event MintRedeemBorrowToggled(uint256 collateralIndex, uint8 toggleIndex);
```

### PoolCeilingSet
Emitted when new pool ceiling (i.e. max amount of collateral) is set


```solidity
event PoolCeilingSet(uint256 collateralIndex, uint256 newCeiling);
```

### PriceThresholdsSet
Emitted when mint and redeem price thresholds are updated (1_000_000 = $1.00)


```solidity
event PriceThresholdsSet(uint256 newMintPriceThreshold, uint256 newRedeemPriceThreshold);
```

### RedemptionDelayBlocksSet
Emitted when a new redemption delay in blocks is set


```solidity
event RedemptionDelayBlocksSet(uint256 redemptionDelayBlocks);
```

## Structs
### UbiquityPoolStorage
Struct used as a storage for this library


```solidity
struct UbiquityPoolStorage {
    mapping(address amoMinter => bool isEnabled) isAmoMinterEnabled;
    address[] collateralAddresses;
    mapping(address collateralAddress => uint256 collateralIndex) collateralIndex;
    address[] collateralPriceFeedAddresses;
    uint256[] collateralPriceFeedStalenessThresholds;
    uint256[] collateralPrices;
    string[] collateralSymbols;
    mapping(address collateralAddress => bool isEnabled) isCollateralEnabled;
    uint256[] missingDecimals;
    uint256[] poolCeilings;
    mapping(address => uint256) lastRedeemedBlock;
    uint256 mintPriceThreshold;
    uint256 redeemPriceThreshold;
    mapping(address user => mapping(uint256 collateralIndex => uint256 amount)) redeemCollateralBalances;
    uint256 redemptionDelayBlocks;
    uint256[] unclaimedPoolCollateral;
    uint256[] mintingFee;
    uint256[] redemptionFee;
    bool[] isBorrowPaused;
    bool[] isMintPaused;
    bool[] isRedeemPaused;
}
```

### CollateralInformation
Struct used for detailed collateral information


```solidity
struct CollateralInformation {
    uint256 index;
    string symbol;
    address collateralAddress;
    address collateralPriceFeedAddress;
    uint256 collateralPriceFeedStalenessThreshold;
    bool isEnabled;
    uint256 missingDecimals;
    uint256 price;
    uint256 poolCeiling;
    bool isMintPaused;
    bool isRedeemPaused;
    bool isBorrowPaused;
    uint256 mintingFee;
    uint256 redemptionFee;
}
```

