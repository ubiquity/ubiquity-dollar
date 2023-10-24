# LibUbiquityPool
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/7c3a0bb87e5e9b32000b3291b4e7da4b119ff3fa/src/dollar/libraries/LibUbiquityPool.sol)

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


### redeemActive

Checks whether redeem is enabled for the `collateralAddress` token


```solidity
modifier redeemActive(address collateralAddress);
```

### mintActive

Checks whether mint is enabled for the `collateralAddress` token


```solidity
modifier mintActive(address collateralAddress);
```

### mintDollar

Mints 1 Ubiquity Dollar for every 1 USD of `collateralAddress` token deposited


```solidity
function mintDollar(address collateralAddress, uint256 collateralAmount, uint256 dollarOutMin)
    internal
    mintActive(collateralAddress);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralAddress`|`address`|address of collateral token being deposited|
|`collateralAmount`|`uint256`|amount of collateral tokens being deposited|
|`dollarOutMin`|`uint256`|minimum amount of Ubiquity Dollars that'll be minted, used to set acceptable slippage|


### redeemDollar

Burns redeemable Ubiquity Dollars and sends back 1 USD of collateral token for every 1 Ubiquity Dollar burned

*Redeem process is split in two steps:*

*1. `redeemDollar()`*

*2. `collectRedemption()`*

*This is done in order to prevent someone using a flash loan of a collateral token to mint, redeem, and collect in a single transaction/block*


```solidity
function redeemDollar(address collateralAddress, uint256 dollarAmount, uint256 collateralOutMin)
    internal
    redeemActive(collateralAddress);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralAddress`|`address`|address of collateral token being withdrawn|
|`dollarAmount`|`uint256`|amount of Ubiquity Dollars being burned|
|`collateralOutMin`|`uint256`|minimum amount of collateral tokens that'll be withdrawn, used to set acceptable slippage|


### collectRedemption

Used to collect collateral tokens after redeeming/burning Ubiquity Dollars

*Redeem process is split in two steps:*

*1. `redeemDollar()`*

*2. `collectRedemption()`*

*This is done in order to prevent someone using a flash loan of a collateral token to mint, redeem, and collect in a single transaction/block*


```solidity
function collectRedemption(address collateralAddress) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralAddress`|`address`|address of the collateral token being collected|


### addToken

Admin function for whitelisting a token as collateral


```solidity
function addToken(address collateralAddress, IMetaPool collateralMetaPool) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralAddress`|`address`|Address of the token being whitelisted|
|`collateralMetaPool`|`IMetaPool`|3CRV Metapool for the token being whitelisted|


### getRedeemCollateralBalances

Returns the amount of collateral ready for collecting after redeeming

*Redeem process is split in two steps:*

*1. `redeemDollar()`*

*2. `collectRedemption()`*

*This is done in order to prevent someone using a flash loan of a collateral token to mint, redeem, and collect in a single transaction/block*


```solidity
function getRedeemCollateralBalances(address account, address collateralAddress) internal view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`account`|`address`|Account address for which to check the balance ready to be collected|
|`collateralAddress`|`address`|Collateral token address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Collateral token balance ready to be collected after redeeming|


### setRedeemActive

Admin function to pause and unpause redemption for a specific collateral token


```solidity
function setRedeemActive(address collateralAddress, bool notRedeemPaused) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralAddress`|`address`|Address of the token being affected|
|`notRedeemPaused`|`bool`|True to turn on redemption for token, false to pause redemption of token|


### getRedeemActive

Checks whether redeem is enabled for the `collateralAddress` token


```solidity
function getRedeemActive(address collateralAddress) internal view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralAddress`|`address`|Token address to check|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|Whether redeem is enabled for the `collateralAddress` token|


### getMintActive

Checks whether mint is enabled for the `collateralAddress` token


```solidity
function getMintActive(address collateralAddress) internal view returns (bool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralAddress`|`address`|Token address to check|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bool`|Whether mint is enabled for the `collateralAddress` token|


### setMintActive

Admin function to pause and unpause minting for a specific collateral token


```solidity
function setMintActive(address collateralAddress, bool notMintPaused) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralAddress`|`address`|Address of the token being affected|
|`notMintPaused`|`bool`|True to turn on minting for token, false to pause minting for token|


### checkCollateralToken

Checks whether `collateralAddress` token is approved by admin to be used as a collateral


```solidity
function checkCollateralToken(address collateralAddress) internal view returns (bool isCollateral);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralAddress`|`address`|Token address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`isCollateral`|`bool`|Whether token is approved to be used as a collateral|


### calcMintDollarAmount

Returns the amount of dollars to mint


```solidity
function calcMintDollarAmount(uint256 collateralAmountD18, uint256 collateralPriceCurve3Pool, uint256 curve3PriceUSD)
    internal
    pure
    returns (uint256 dollarOut);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralAmountD18`|`uint256`|Amount of collateral tokens|
|`collateralPriceCurve3Pool`|`uint256`|USD price of a single collateral token|
|`curve3PriceUSD`|`uint256`|USD price from the Curve Tri-Pool (DAI, USDC, USDT)|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`dollarOut`|`uint256`|Amount of Ubiquity Dollars to mint|


### calcRedeemCollateralAmount

Returns the amount of collateral tokens ready for collecting

*Redeem process is split in two steps:*

*1. `redeemDollar()`*

*2. `collectRedemption()`*

*This is done in order to prevent someone using a flash loan of a collateral token to mint, redeem, and collect in a single transaction/block*


```solidity
function calcRedeemCollateralAmount(uint256 dollarAmountD18, uint256 collateralPriceCurve3Pool, uint256 curve3PriceUSD)
    internal
    pure
    returns (uint256 collateralOut);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`dollarAmountD18`|`uint256`|Amount of Ubiquity Dollars to redeem|
|`collateralPriceCurve3Pool`|`uint256`|USD price of a single collateral token|
|`curve3PriceUSD`|`uint256`|USD price from the Curve Tri-Pool (DAI, USDC, USDT)|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`collateralOut`|`uint256`|Amount of collateral tokens ready to be collectable|


### getDollarPriceUsd

Returns Ubiquity Dollar token USD price from Metapool (Ubiquity Dollar, Curve Tri-Pool LP)


```solidity
function getDollarPriceUsd() internal view returns (uint256 dollarPriceUSD);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`dollarPriceUSD`|`uint256`|USD price of Ubiquity Dollar|


### getCollateralPriceCurve3Pool

Returns the latest price of the `collateralAddress` token from Curve Metapool


```solidity
function getCollateralPriceCurve3Pool(address collateralAddress)
    internal
    view
    returns (uint256 collateralPriceCurve3Pool);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralAddress`|`address`|Collateral token address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`collateralPriceCurve3Pool`|`uint256`|Collateral token price from Curve Metapool|


### getCurve3PriceUSD

Returns USD price from Tri-Pool (DAI, USDC, USDT)


```solidity
function getCurve3PriceUSD() internal view returns (uint256 curve3PriceUSD);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`curve3PriceUSD`|`uint256`|USD price|


## Structs
### UbiquityPoolStorage
Struct used as a storage for this library


```solidity
struct UbiquityPoolStorage {
    address[] collateralAddresses;
    mapping(address => IMetaPool) collateralMetaPools;
    mapping(address => uint8) missingDecimals;
    mapping(address => uint256) tokenBalances;
    mapping(address => bool) collateralRedeemActive;
    mapping(address => bool) collateralMintActive;
    uint256 mintingFee;
    uint256 redemptionFee;
    mapping(address => mapping(address => uint256)) redeemCollateralBalances;
    mapping(address => uint256) unclaimedPoolCollateral;
    mapping(address => uint256) lastRedeemed;
    uint256 poolCeiling;
    uint256 pausedPrice;
    uint256 redemptionDelay;
    uint256 dollarFloor;
}
```

