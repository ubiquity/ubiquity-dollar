# StakingFacet
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/b3082cd78c54c73c487f0fe24d8f9b24a6ac0c9e/src/dollar/facets/StakingFacet.sol)

**Inherits:**
[IStaking](/src/dollar/interfaces/IStaking.sol/interface.IStaking.md), [Modifiers](/src/dollar/libraries/LibAppStorage.sol/contract.Modifiers.md)

Ubiquity staking facet


## Functions
### getPendingStakingRewards

View function to see pending Governance tokens on frontend


```solidity
function getPendingStakingRewards(uint256 poolId, address user) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`poolId`|`uint256`|Pool id|
|`user`|`address`|User address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Staking rewards amount|


### getStakingMultiplier

Returns reward multiplier over the given `from` to `to` blocks


```solidity
function getStakingMultiplier(uint256 from, uint256 to) external view returns (uint256);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`from`|`uint256`|From block number|
|`to`|`uint256`|To block number|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Reward multiplier|


### getStakingSettings

Returns staking settings


```solidity
function getStakingSettings()
    external
    view
    returns (address, uint256, uint256, uint256, uint256, uint256, uint256, uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|Returns: - Reward token address - Bonus end block - Governance token bonus multiplier - Governance tokens minted per block - Governance token divider for treasury - Total available reward amount - Total allocation points across all staking pools - Start block when staking starts|
|`<none>`|`uint256`||
|`<none>`|`uint256`||
|`<none>`|`uint256`||
|`<none>`|`uint256`||
|`<none>`|`uint256`||
|`<none>`|`uint256`||
|`<none>`|`uint256`||


### getStakingUserInfo

View function to see user's staking info


```solidity
function getStakingUserInfo(uint256 poolId, address user) external view returns (LibStaking.UserInfo memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`poolId`|`uint256`|Pool id|
|`user`|`address`|User address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`LibStaking.UserInfo`|User's staking info|


### getStakingPoolInfo

View function to see pool's staking info


```solidity
function getStakingPoolInfo(uint256 poolId) external view returns (LibStaking.PoolInfo memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`poolId`|`uint256`|Pool id|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`LibStaking.PoolInfo`|Pool's staking info|


### getStakingPoolsLength

Returns total staking pools length


```solidity
function getStakingPoolsLength() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Pools length|


### massUpdateStakingPools

Updates reward variables for all pools


```solidity
function massUpdateStakingPools() external whenNotPaused nonReentrant;
```

### stake

Stakes LP tokens to the staking contract for Governance tokens allocation


```solidity
function stake(uint256 poolId, uint256 amount) external whenNotPaused nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`poolId`|`uint256`|Pool id|
|`amount`|`uint256`|Amount of LP tokens to stake|


### unstake

Unstakes LP tokens from the staking contract


```solidity
function unstake(uint256 poolId, uint256 amount) external whenNotPaused nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`poolId`|`uint256`|Pool id|
|`amount`|`uint256`|Amount of LP tokens to unstake|


### updateStakingPool

Updates reward variables of the given pool to be up-to-date


```solidity
function updateStakingPool(uint256 poolId) external whenNotPaused nonReentrant;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`poolId`|`uint256`|Pool id|


### createStakingPool

Adds a new staking pool


```solidity
function createStakingPool(uint256 allocationPoints, IERC20 lpToken) external onlyAdmin;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`allocationPoints`|`uint256`|Allocation points|
|`lpToken`|`IERC20`|LP token, can't overlap with collateral tokens from `UbiquityPool`|


### setGovernanceBonusEndBlock

Sets last block number when Governance bonus emissions end


```solidity
function setGovernanceBonusEndBlock(uint256 newGovernanceBonusEndBlock) external onlyAdmin;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newGovernanceBonusEndBlock`|`uint256`|Block number when Governance bonus emissions end|


### setGovernanceBonusMultiplier

Sets bonus multiplier for early Governance token makers


```solidity
function setGovernanceBonusMultiplier(uint256 newGovernanceBonusMultiplier) external onlyAdmin;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newGovernanceBonusMultiplier`|`uint256`|New governance bonus multiplier|


### setGovernancePerBlock

Sets Governance tokens reward per block

*If `newGovernancePerBlock < 0.0001 ether` users may end up getting 0 rewards
if staked amount > 1_000_000_000e18*


```solidity
function setGovernancePerBlock(uint256 newGovernancePerBlock) external onlyAdmin;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newGovernancePerBlock`|`uint256`|New amount of Governance tokens minted each block|


### setGovernanceTreasuryDivider

Sets Governance token divider param for treasury. The bigger `governanceTreasuryDivider` the less extra
Governance tokens will be minted for the treasury.


```solidity
function setGovernanceTreasuryDivider(uint256 newGovernanceTreasuryDivider) external onlyAdmin;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newGovernanceTreasuryDivider`|`uint256`|New governance divider param value|


### setStakingRewardToken

Sets staking reward token


```solidity
function setStakingRewardToken(address newRewardToken) external onlyAdmin;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newRewardToken`|`address`|New reward token address, can't overlap with collateral tokens from `UbiquityPool`|


### setStakingStartBlock

Sets start block when staking should be active


```solidity
function setStakingStartBlock(uint256 newStartBlock) external onlyAdmin;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newStartBlock`|`uint256`|Block number when staking should be active|


### updateStakingPool

Updates reward variables of the given pool to be up-to-date


```solidity
function updateStakingPool(uint256 poolId, uint256 allocationPoints) external onlyAdmin;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`poolId`|`uint256`|Pool id|
|`allocationPoints`|`uint256`||


