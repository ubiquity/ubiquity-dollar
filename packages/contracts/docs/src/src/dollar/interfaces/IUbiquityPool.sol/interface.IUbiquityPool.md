# IUbiquityPool
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/940040226cc8480b0e7aa65d1592259dfcf013ef/src/dollar/interfaces/IUbiquityPool.sol)

Ubiquity pool interface

Allows users to:
- deposit collateral in exchange for Ubiquity Dollars
- redeem Ubiquity Dollars in exchange for the earlier provided collateral


## Functions
### allCollaterals

Returns all collateral addresses


```solidity
function allCollaterals() external view returns (address[] memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address[]`|All collateral addresses|


### collateralInformation

Returns collateral information


```solidity
function collateralInformation(address collateralAddress)
    external
    view
    returns (LibUbiquityPool.CollateralInformation memory returnData);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralAddress`|`address`|Address of the collateral token|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`returnData`|`LibUbiquityPool.CollateralInformation`|Collateral info|


### collateralUsdBalance

Returns USD value of all collateral tokens held in the pool, in E18


```solidity
function collateralUsdBalance() external view returns (uint256 balanceTally);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`balanceTally`|`uint256`|USD value of all collateral tokens|


### freeCollateralBalance

Returns free collateral balance (i.e. that can be borrowed by AMO minters)


```solidity
function freeCollateralBalance(uint256 collateralIndex) external view returns (uint256);
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
function getDollarInCollateral(uint256 collateralIndex, uint256 dollarAmount) external view returns (uint256);
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
function getDollarPriceUsd() external view returns (uint256 dollarPriceUsd);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`dollarPriceUsd`|`uint256`|USD price of Ubiquity Dollar|


### mintDollar

Mints Dollars in exchange for collateral tokens


```solidity
function mintDollar(uint256 collateralIndex, uint256 dollarAmount, uint256 dollarOutMin, uint256 maxCollateralIn)
    external
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
    external
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
function collectRedemption(uint256 collateralIndex) external returns (uint256 collateralAmount);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralIndex`|`uint256`|Collateral token index being collected|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`collateralAmount`|`uint256`|Amount of collateral tokens redeemed|


### amoMinterBorrow

Allows AMO minters to borrow collateral to make yield in external
protocols like Compound, Curve, erc...

*Bypasses the gassy mint->redeem cycle for AMOs to borrow collateral*


```solidity
function amoMinterBorrow(uint256 collateralAmount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralAmount`|`uint256`|Amount of collateral to borrow|


### addAmoMinter

Adds a new AMO minter


```solidity
function addAmoMinter(address amoMinterAddress) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amoMinterAddress`|`address`|AMO minter address|


### addCollateralToken

Adds a new collateral token


```solidity
function addCollateralToken(address collateralAddress, address chainLinkPriceFeedAddress, uint256 poolCeiling)
    external;
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
function removeAmoMinter(address amoMinterAddress) external;
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
) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralAddress`|`address`|Collateral token address|
|`chainLinkPriceFeedAddress`|`address`|ChainLink price feed address|
|`stalenessThreshold`|`uint256`|Threshold in seconds when chainlink answer should be considered stale|


### updateChainLinkCollateralPrice

Updates collateral token price in USD from ChainLink price feed


```solidity
function updateChainLinkCollateralPrice(uint256 collateralIndex) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralIndex`|`uint256`|Collateral token index|


### setFees

Sets mint and redeem fees, 1_000_000 = 100%


```solidity
function setFees(uint256 collateralIndex, uint256 newMintFee, uint256 newRedeemFee) external;
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
function setPoolCeiling(uint256 collateralIndex, uint256 newCeiling) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralIndex`|`uint256`|Collateral token index|
|`newCeiling`|`uint256`|Max amount of collateral|


### setPriceThresholds

Sets mint and redeem price thresholds, 1_000_000 = $1.00


```solidity
function setPriceThresholds(uint256 newMintPriceThreshold, uint256 newRedeemPriceThreshold) external;
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
function setRedemptionDelayBlocks(uint256 newRedemptionDelayBlocks) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newRedemptionDelayBlocks`|`uint256`|Redemption delay in blocks|


### toggleCollateral

Toggles (i.e. enables/disables) a particular collateral token


```solidity
function toggleCollateral(uint256 collateralIndex) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralIndex`|`uint256`|Collateral token index|


### toggleMintRedeemBorrow

Toggles pause for mint/redeem/borrow methods


```solidity
function toggleMintRedeemBorrow(uint256 collateralIndex, uint8 toggleIndex) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`collateralIndex`|`uint256`|Collateral token index|
|`toggleIndex`|`uint8`|Method index. 0 - toggle mint pause, 1 - toggle redeem pause, 2 - toggle borrow by AMO pause|


