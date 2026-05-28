# LibStaking
[Git Source](https://github.com/ubiquity/ubiquity-dollar/blob/b3082cd78c54c73c487f0fe24d8f9b24a6ac0c9e/src/dollar/libraries/LibStaking.sol)

Ubiquity staking contract

*Derived from https://github.com/sushi-labs/sushiswap/blob/271458b558afa6fdfd3e46b8eef5ee6618b60f9d/contracts/MasterChef.sol*


## State Variables
### STAKING_STORAGE_POSITION
Storage slot used to store data for this library


```solidity
bytes32 constant STAKING_STORAGE_POSITION =
    bytes32(uint256(keccak256("ubiquity.contracts.staking.storage")) - 1) & ~bytes32(uint256(0xff));
```


## Functions
### stakingStorage

Returns struct used as a storage for this library


```solidity
function stakingStorage() internal pure returns (StakingStorage storage stakingStore);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`stakingStore`|`StakingStorage`|Struct used as a storage|


### getPendingStakingRewards

View function to see pending Governance tokens on frontend


```solidity
function getPendingStakingRewards(uint256 poolId, address user) internal view returns (uint256);
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
function getStakingMultiplier(uint256 from, uint256 to) internal view returns (uint256);
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
    internal
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
function getStakingUserInfo(uint256 poolId, address user) internal view returns (UserInfo memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`poolId`|`uint256`|Pool id|
|`user`|`address`|User address|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`UserInfo`|User's staking info|


### getStakingPoolInfo

View function to see pool's staking info


```solidity
function getStakingPoolInfo(uint256 poolId) internal view returns (PoolInfo memory);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`poolId`|`uint256`|Pool id|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`PoolInfo`|Pool's staking info|


### getStakingPoolsLength

Returns total staking pools length


```solidity
function getStakingPoolsLength() internal view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|Pools length|


### massUpdateStakingPools

Updates reward variables for all pools


```solidity
function massUpdateStakingPools() internal;
```

### stake

Stakes LP tokens to the staking contract for Governance tokens allocation


```solidity
function stake(uint256 poolId, uint256 amount) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`poolId`|`uint256`|Pool id|
|`amount`|`uint256`|Amount of LP tokens to stake|


### unstake

Unstakes LP tokens from the staking contract


```solidity
function unstake(uint256 poolId, uint256 amount) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`poolId`|`uint256`|Pool id|
|`amount`|`uint256`|Amount of LP tokens to unstake|


### updateStakingPool

Updates reward variables of the given pool to be up-to-date


```solidity
function updateStakingPool(uint256 poolId) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`poolId`|`uint256`|Pool id|


### createStakingPool

Adds a new staking pool

The following LP tokens with "weird" ERC20 behavior are not supported:
- Fee on Transfer: https://github.com/d-xo/weird-erc20?tab=readme-ov-file#fee-on-transfer
- Rebasing: https://github.com/d-xo/weird-erc20?tab=readme-ov-file#balance-modifications-outside-of-transfers-rebasingairdrops
- Pausable Tokens: https://github.com/d-xo/weird-erc20?tab=readme-ov-file#pausable-tokens
- Transfer of less than amount: https://github.com/d-xo/weird-erc20?tab=readme-ov-file#transfer-of-less-than-amount


```solidity
function createStakingPool(uint256 allocationPoints, IERC20 lpToken) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`allocationPoints`|`uint256`|Allocation points|
|`lpToken`|`IERC20`|LP token, can't overlap with collateral tokens from `UbiquityPool`|


### setGovernanceBonusEndBlock

Sets last block number when Governance bonus emissions end


```solidity
function setGovernanceBonusEndBlock(uint256 newGovernanceBonusEndBlock) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newGovernanceBonusEndBlock`|`uint256`|Block number when Governance bonus emissions end|


### setGovernanceBonusMultiplier

Sets bonus multiplier for early Governance token makers


```solidity
function setGovernanceBonusMultiplier(uint256 newGovernanceBonusMultiplier) internal;
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
function setGovernancePerBlock(uint256 newGovernancePerBlock) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newGovernancePerBlock`|`uint256`|New amount of Governance tokens minted each block|


### setGovernanceTreasuryDivider

Sets Governance token divider param for treasury. The bigger `governanceTreasuryDivider` the less extra
Governance tokens will be minted for the treasury.

Example: if `governanceTreasuryDivider = 5` then `100 / 5 = 20%` extra minted Governance tokens for treasury

Set `governanceTreasuryDivider` to 0 if you want to disable minting rewards to the treasury


```solidity
function setGovernanceTreasuryDivider(uint256 newGovernanceTreasuryDivider) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newGovernanceTreasuryDivider`|`uint256`|New governance divider param value|


### setStakingRewardToken

Sets staking reward token

The following reward tokens with "weird" ERC20 behavior are not supported:
- Rebasing: https://github.com/d-xo/weird-erc20?tab=readme-ov-file#balance-modifications-outside-of-transfers-rebasingairdrops
- Pausable Tokens: https://github.com/d-xo/weird-erc20?tab=readme-ov-file#pausable-tokens
- Transfer of less than amount: https://github.com/d-xo/weird-erc20?tab=readme-ov-file#transfer-of-less-than-amount


```solidity
function setStakingRewardToken(address newRewardToken) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newRewardToken`|`address`|New reward token address, can't overlap with collateral tokens from `UbiquityPool`|


### setStakingStartBlock

Sets start block when staking should be active


```solidity
function setStakingStartBlock(uint256 newStartBlock) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newStartBlock`|`uint256`|Block number when staking should be active|


### updateStakingPool

Updates the given pool's Governance token allocation points


```solidity
function updateStakingPool(uint256 poolId, uint256 allocationPoints) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`poolId`|`uint256`|Pool id|
|`allocationPoints`|`uint256`|New allocation points|


### safeGovernanceTransfer

Safe Governance token transfer function


```solidity
function safeGovernanceTransfer(address to, uint256 amount) internal;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|Receiver address|
|`amount`|`uint256`|Amount to transfer|


## Events
### GovernanceBonusEndBlockSet
Emitted when new governance bonus end block parameter set


```solidity
event GovernanceBonusEndBlockSet(uint256 indexed newGovernanceBonusEndBlock);
```

### GovernanceBonusMultiplierSet
Emitted when new governance bonus multiplier parameter set


```solidity
event GovernanceBonusMultiplierSet(uint256 indexed newGovernanceBonusMultiplier);
```

### GovernancePerBlockSet
Emitted when new governance per block parameter set


```solidity
event GovernancePerBlockSet(uint256 indexed newGovernancePerBlock);
```

### GovernanceTreasuryDividerSet
Emitted when new governance treasury divider parameter set


```solidity
event GovernanceTreasuryDividerSet(uint256 indexed newGovernanceTreasuryDivider);
```

### Stake
Emitted on staking LP tokens


```solidity
event Stake(address indexed user, uint256 indexed poolId, uint256 amount);
```

### StakingPoolCreated
Emitted when new staking pool created


```solidity
event StakingPoolCreated(uint256 indexed allocationPoints, address indexed lpToken);
```

### StakingPoolUpdated
Emitted on updating staking pool rewards


```solidity
event StakingPoolUpdated(uint256 indexed poolId);
```

### StakingPoolAllocationUpdated
Emitted when staking pool allocation updated


```solidity
event StakingPoolAllocationUpdated(uint256 indexed poolId, uint256 indexed allocationPoints);
```

### StakingRewardTokenSet
Emitted when new reward token address set


```solidity
event StakingRewardTokenSet(address indexed newRewardToken);
```

### StakingStartBlockSet
Emitted when new staking start block set


```solidity
event StakingStartBlockSet(uint256 indexed newStartBlock);
```

### Unstake
Emitted on unstaking LP tokens


```solidity
event Unstake(address indexed user, uint256 indexed poolId, uint256 amount);
```

## Structs
### UserInfo
Info of each user

*Reward debt explanation:
We do some fancy math here. Basically, any point in time, the amount of Governance tokens
entitled to a user but is pending to be distributed is:
pending reward = (user.amount * pool.accumulatedGovernancePerShare) - user.rewardDebt
Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
1. The pool's `accumulatedGovernancePerShare` (and `lastRewardBlock`) gets updated.
2. User receives the pending reward sent to his/her address.
3. User's `amount` gets updated.
4. User's `rewardDebt` gets updated.*


```solidity
struct UserInfo {
    uint256 amount;
    uint256 rewardDebt;
}
```

### PoolInfo
Info of each pool


```solidity
struct PoolInfo {
    IERC20 lpToken;
    uint256 amount;
    uint256 allocationPoints;
    uint256 lastRewardBlock;
    uint256 accumulatedGovernancePerShare;
}
```

### StakingStorage
Struct used as a storage for this library


```solidity
struct StakingStorage {
    IERC20Ubiquity rewardToken;
    uint256 bonusEndBlock;
    uint256 governanceBonusMultiplier;
    uint256 governancePerBlock;
    uint256 governanceTreasuryDivider;
    uint256 rewardAmount;
    PoolInfo[] poolInfo;
    mapping(uint256 poolId => mapping(address user => UserInfo)) userInfo;
    uint256 totalAllocationPoints;
    uint256 startBlock;
}
```

