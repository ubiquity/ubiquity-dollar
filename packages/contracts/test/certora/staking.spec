using UbiquityGovernance as ubqToken;
using UbiquityAlgorithmicDollarManager as dollarManager;

methods {
    function _.mint(address, uint256) external => DISPATCHER(true);
    function _.transfer(address, uint256) external => DISPATCHER(true);
    function _.transferFrom(address, address, uint256) external => DISPATCHER(true);
}

// default role admin
definition DEFAULT_ADMIN_ROLE() returns bytes32 = to_bytes32(0);
// filters methods only from `StakingFacet`
definition isStakingFacetMethod (method f) returns bool = 
    // exlude diamond fallback
    !f.isFallback && (
        // views
        f.selector == sig:getPendingStakingRewards(uint256,address).selector ||
        f.selector == sig:getStakingMultiplier(uint256,uint256).selector ||
        f.selector == sig:getStakingSettings().selector ||
        f.selector == sig:getStakingUserInfo(uint256,address).selector ||
        f.selector == sig:getStakingPoolInfo(uint256).selector ||
        f.selector == sig:getStakingPoolsLength().selector ||
        // public
        f.selector == sig:massUpdateStakingPools().selector ||
        f.selector == sig:unstake(uint256,uint256).selector ||
        f.selector == sig:stake(uint256,uint256).selector ||
        f.selector == sig:updateStakingPool(uint256).selector ||
        // restricted
        f.selector == sig:createStakingPool(uint256,address).selector ||
        f.selector == sig:setGovernanceBonusEndBlock(uint256).selector ||
        f.selector == sig:setGovernanceBonusMultiplier(uint256).selector ||
        f.selector == sig:setGovernancePerBlock(uint256).selector ||
        f.selector == sig:setGovernanceTreasuryDivider(uint256).selector ||
        f.selector == sig:setStakingRewardToken(address).selector ||
        f.selector == sig:setStakingStartBlock(uint256).selector ||
        f.selector == sig:updateStakingPool(uint256,uint256).selector
    );
// reentrancy status "not entered"
definition REENTRANCY_STATUS_NOT_ENTERED() returns uint256 = 1;

//========
// High
//========

// `pool.accumulatedGovernancePerShare` only increases
rule high_accumulatedGovernancePerShareMonotonic(method f) filtered { f -> isStakingFacetMethod(f) } {
    uint256 poolId;    
    env e;

    LibStaking.PoolInfo poolInfoBefore = getStakingPoolInfo(e, poolId);

    calldataarg args;
    f(e, args);

    LibStaking.PoolInfo poolInfoAfter = getStakingPoolInfo(e, poolId);

    assert 
        poolInfoAfter.accumulatedGovernancePerShare >= poolInfoBefore.accumulatedGovernancePerShare,
        "accumulatedGovernancePerShare must only increase";
}

//=================
// Unit (public)
//=================

// `massUpdateStakingPools` for a single pool must have the same effect on storage as calling `updateStakingPool`
rule unit_massUpdateStakingPools_MustUpdateStorageAsExpected() {
    env e;
    uint256 poolId;

    storage initialStorage = lastStorage;

    massUpdateStakingPools(e);
    storage afterMassUpdateStorage = lastStorage;

    updateStakingPool(e, poolId) at initialStorage;
    storage afterSingleUpdateStorage = lastStorage;

    assert afterMassUpdateStorage == afterSingleUpdateStorage, "Storage must be updated as expected";
}

// `stake` increases user rewads
rule unit_stake_MustIncreaseUserRewards() {
    env e;
    uint256 poolId;
    uint256 amount;
    address user;
    address rewardToken;

    LibStaking.UserInfo userInfo = getStakingUserInfo(e, poolId, user);
    LibStaking.PoolInfo poolInfo = getStakingPoolInfo(e, poolId);
    (rewardToken, _, _, _, _, _, _, _) = getStakingSettings(e);

    // user has pending rewards
    require userInfo.amount > 0;
    // user only wants to collect rewards
    require amount == 0;
    // set user as `msg.sender`
    require e.msg.sender == user;
    // prevent overflow
    require ubqToken.balanceOf(e, user) == 0;

    mathint rewardBalanceBefore = ubqToken.balanceOf(e, user);

    stake(e, poolId, amount);

    mathint rewardBalanceAfter = ubqToken.balanceOf(e, user);

    assert rewardBalanceAfter >= rewardBalanceBefore, "User rewards only increase";
}

// `stake` transfers staked tokens
rule unit_stake_MustTransferStakedToken() {
    env e;
    uint256 poolId;
    uint256 amount;
    address user;

    LibStaking.UserInfo userInfo = getStakingUserInfo(e, poolId, user);
    LibStaking.PoolInfo poolInfo = getStakingPoolInfo(e, poolId);

    // user has not pending rewards
    require userInfo.amount == 0;
    // current contract is not diamond
    require e.msg.sender != currentContract;
    // set user as `msg.sender`
    require e.msg.sender == user;
    // user is not treasury
    require(treasuryAddress(e) != user);

    mathint userBalanceBefore = ubqToken.balanceOf(e, user);

    stake(e, poolId, amount);

    mathint userBalanceAfter = ubqToken.balanceOf(e, user);

    assert userBalanceAfter + amount == userBalanceBefore, "Staked tokens must be transfered";
}

// `stake` updates storage as expected
rule unit_stake_MustUpdateStorageAsExpected() {
    env e;
    uint256 poolId;
    uint256 amount;
    address user;

    // set user as `msg.sender`
    require e.msg.sender == user;

    LibStaking.UserInfo userInfoBefore = getStakingUserInfo(e, poolId, user);
    LibStaking.PoolInfo poolInfoBefore = getStakingPoolInfo(e, poolId);

    stake(e, poolId, amount);

    LibStaking.UserInfo userInfoAfter = getStakingUserInfo(e, poolId, user);
    LibStaking.PoolInfo poolInfoAfter = getStakingPoolInfo(e, poolId);

    assert userInfoBefore.amount + amount == userInfoAfter.amount, "User staked amount increases";
    assert poolInfoBefore.amount + amount == poolInfoAfter.amount, "Pool staked amount increases";
}

// `stake` must not affect other users
rule unit_stake_MustNotAffectOtherUsers() {
    env e;
    uint256 poolId;
    uint256 amount;
    address user;
    address otherUser;

    // set user as `msg.sender`
    require e.msg.sender == user;
    // users are different
    require otherUser != user;

    LibStaking.UserInfo otherUserInfoBefore = getStakingUserInfo(e, poolId, otherUser);

    stake(e, poolId, amount);

    LibStaking.UserInfo otherUserInfoAfter = getStakingUserInfo(e, poolId, otherUser);

    assert otherUserInfoBefore == otherUserInfoAfter, "Other user not affected";
}

// `stake` must not affect other pools
rule unit_stake_MustNotAffectOtherPools() {
    env e;
    uint256 poolId;
    uint256 otherPoolId;
    uint256 amount;
    address user;

    // set user as `msg.sender`
    require e.msg.sender == user;
    // pools are different
    require otherPoolId != poolId;

    LibStaking.PoolInfo otherPoolInfoBefore = getStakingPoolInfo(e, otherPoolId);

    stake(e, poolId, amount);

    LibStaking.PoolInfo otherPoolInfoAfter = getStakingPoolInfo(e, otherPoolId);

    assert otherPoolInfoBefore == otherPoolInfoAfter, "Other pool not affected";
}

// `unstake` increases user rewads
rule unit_unstake_MustIncreaseUserRewards() {
    env e;
    uint256 poolId;
    uint256 amount;
    address user;
    address rewardToken;

    LibStaking.UserInfo userInfo = getStakingUserInfo(e, poolId, user);
    LibStaking.PoolInfo poolInfo = getStakingPoolInfo(e, poolId);
    (rewardToken, _, _, _, _, _, _, _) = getStakingSettings(e);

    // user has pending rewards
    require userInfo.amount > 0;
    // user has sufficient amount to withdraw
    require amount <= userInfo.amount;
    // set user as `msg.sender`
    require e.msg.sender == user;
    // prevent overflow
    require ubqToken.balanceOf(e, user) == 0;

    mathint rewardBalanceBefore = ubqToken.balanceOf(e, user);

    unstake(e, poolId, amount);

    mathint rewardBalanceAfter = ubqToken.balanceOf(e, user);

    assert rewardBalanceAfter >= rewardBalanceBefore, "User rewards only increase";
}

// `unstake` updates storage as expected
rule unit_unstake_MustUpdateStorageAsExpected() {
    env e;
    uint256 poolId;
    uint256 amount;
    address user;

    // set user as `msg.sender`
    require e.msg.sender == user;

    LibStaking.UserInfo userInfoBefore = getStakingUserInfo(e, poolId, user);
    LibStaking.PoolInfo poolInfoBefore = getStakingPoolInfo(e, poolId);

    unstake(e, poolId, amount);

    LibStaking.UserInfo userInfoAfter = getStakingUserInfo(e, poolId, user);
    LibStaking.PoolInfo poolInfoAfter = getStakingPoolInfo(e, poolId);

    assert userInfoBefore.amount == userInfoAfter.amount + amount, "User staked amount decreases";
    assert poolInfoBefore.amount == poolInfoAfter.amount + amount, "Pool staked amount decreases";
}

// `unstake` transfers staked tokens
rule unit_unstake_MustTransferStakedToken() {
    env e;
    uint256 poolId;
    uint256 amount;
    address user;

    LibStaking.UserInfo userInfo = getStakingUserInfo(e, poolId, user);
    LibStaking.PoolInfo poolInfo = getStakingPoolInfo(e, poolId);

    // user has some funds staked
    require userInfo.amount > 0;
    // current contract is not diamond
    require e.msg.sender != currentContract;
    // set user as `msg.sender`
    require e.msg.sender == user;
    // prevent overflow
    require amount < 100000000000000000000000000; // 100mln
    require(ubqToken.balanceOf(e, user) == 0);

    mathint userBalanceBefore = ubqToken.balanceOf(e, user);

    unstake(e, poolId, amount);

    mathint userBalanceAfter = ubqToken.balanceOf(e, user);

    assert userBalanceAfter >= userBalanceBefore + amount, "Staked tokens must be transfered";
}

// `unstake` must not affect other users
rule unit_unstake_MustNotAffectOtherUsers() {
    env e;
    uint256 poolId;
    uint256 amount;
    address user;
    address otherUser;

    // set user as `msg.sender`
    require e.msg.sender == user;
    // users are different
    require otherUser != user;

    LibStaking.UserInfo otherUserInfoBefore = getStakingUserInfo(e, poolId, otherUser);

    unstake(e, poolId, amount);

    LibStaking.UserInfo otherUserInfoAfter = getStakingUserInfo(e, poolId, otherUser);

    assert otherUserInfoBefore == otherUserInfoAfter, "Other user not affected";
}

// `unstake` must not affect other pools
rule unit_unstake_MustNotAffectOtherPools() {
    env e;
    uint256 poolId;
    uint256 otherPoolId;
    uint256 amount;
    address user;

    // set user as `msg.sender`
    require e.msg.sender == user;
    // pools are different
    require otherPoolId != poolId;

    LibStaking.PoolInfo otherPoolInfoBefore = getStakingPoolInfo(e, otherPoolId);

    unstake(e, poolId, amount);

    LibStaking.PoolInfo otherPoolInfoAfter = getStakingPoolInfo(e, otherPoolId);

    assert otherPoolInfoBefore == otherPoolInfoAfter, "Other pool not affected";
}

// `unstake` must not transfer more staked tokens than expected
rule unit_unstake_UserMustNotBeAbleToUnstakeMoreThanExpected() {
    env e;
    uint256 poolId;
    uint256 amount;
    address user;

    // set user as `msg.sender`
    require e.msg.sender == user;

    LibStaking.UserInfo userInfo = getStakingUserInfo(e, poolId, user);
    require amount > userInfo.amount;

    unstake@withrevert(e, poolId, amount);

    assert lastReverted, "User can not unstake more than expected";
}

// `updateStakingPool` does not update a pool if:
// 1. The pool has already been updated in the current block
// 2. Pool's LP supply is 0
rule unit_updateStakingPoolRewards_UpdatesPoolRewardsOnlyInExpectedCases() {
    env e;
    uint256 poolId;

    // at least 3 pools exist
    require(poolId > 1);
    require(getStakingPoolsLength(e) == poolId + 1);

    LibStaking.PoolInfo poolInfoBefore = getStakingPoolInfo(e, poolId);

    updateStakingPool(e, poolId);

    LibStaking.PoolInfo poolInfoAfter = getStakingPoolInfo(e, poolId);

    assert 
        (poolInfoBefore == poolInfoAfter) => (e.block.number <= poolInfoBefore.lastRewardBlock) || (poolInfoBefore.amount == 0),
        "Pool rewards updated unexpectedly";
}

// `updateStakingPool` mints rewards to diamond
rule unit_updateStakingPoolRewards_MintsRewardsToDiamond() {
    env e;
    uint256 poolId;
    address treasury;

    // prevent overflow
    require(ubqToken.balanceOf(e, currentContract) == 0);

    uint256 diamondRewardsBefore = ubqToken.balanceOf(e, currentContract);

    updateStakingPool(e, poolId);

    uint256 diamondRewardsAfter = ubqToken.balanceOf(e, currentContract);

    assert diamondRewardsAfter >= diamondRewardsBefore, "Diamond reward balance only increases";
}

// `updateStakingPool` mints rewards to treasury
rule unit_updateStakingPoolRewards_MintsRewardsToTreasury() {
    env e;
    uint256 poolId;
    address treasury;

    // set treasury address
    require(treasuryAddress(e) == treasury);
    // prevent overflow
    require(ubqToken.balanceOf(e, treasury) == 0);

    mathint treasuryRewardsBefore = ubqToken.balanceOf(e, treasury);

    updateStakingPool(e, poolId);

    mathint treasuryRewardsAfter = ubqToken.balanceOf(e, treasury);

    assert treasuryRewardsAfter >= treasuryRewardsBefore, "Treasury reward balance only increases";
}

// `updateStakingPool` updates storage as expected
rule unit_updateStakingPoolRewards_MustUpdateStorageAsExpected() {
    env e;
    uint256 poolId;
    mathint totalRewardAmountBefore;
    mathint totalRewardAmountAfter;

    // at least 3 pools exist
    require(poolId > 1);
    require(getStakingPoolsLength(e) == poolId + 1);

    LibStaking.PoolInfo poolInfoBefore = getStakingPoolInfo(e, poolId);
    (_, _, _, _, _, totalRewardAmountBefore, _, _) = getStakingSettings(e);

    updateStakingPool(e, poolId);

    LibStaking.PoolInfo poolInfoAfter = getStakingPoolInfo(e, poolId);
    (_, _, _, _, _, totalRewardAmountAfter, _, _) = getStakingSettings(e);

    assert 
        poolInfoAfter.accumulatedGovernancePerShare >= poolInfoBefore.accumulatedGovernancePerShare, 
        "Accumulated governance per share always increases";
    assert 
        e.block.number > poolInfoBefore.lastRewardBlock => poolInfoAfter.lastRewardBlock == e.block.number, 
        "Pool's last reward block must be updated";
    assert
        totalRewardAmountAfter >= totalRewardAmountBefore,
        "Total reward amount always increases";
}

// `updateStakingPool` must not revert unexpectedly
rule unit_updateStakingPoolRewards_MustNotRevertUnexpectedly() {
    env e;
    uint256 poolId;
    uint256 from;
    uint256 to;
    uint256 bonusEndBlock;
    uint256 governanceBonusMultiplier;
    uint256 governancePerBlock;
    uint256 governanceTreasuryDivider;
    uint256 rewardAmount;
    uint256 totalAllocationPoints;

    (_, bonusEndBlock, governanceBonusMultiplier, governancePerBlock, governanceTreasuryDivider, rewardAmount, totalAllocationPoints, _) = getStakingSettings(e);
    LibStaking.PoolInfo poolInfo = getStakingPoolInfo(e, poolId);

    // prevent overflows
    require e.block.number < 2628000 * 10; // block numbers in 10 years
    require governancePerBlock < 100000000000000000000000; // 100k ether
    require governanceBonusMultiplier < 100;
    require bonusEndBlock < 2628000 * 10; // block numbers in 10 years
    require poolInfo.allocationPoints < 100000;
    require poolInfo.accumulatedGovernancePerShare == 0;
    require totalAllocationPoints > 0;
    require governanceTreasuryDivider > 0;
    require rewardAmount == 0;
    // prevent edge cases
    require(treasuryAddress(e) != 0);
    require !ubqToken.paused(e);
    require ubqToken.totalSupply(e) < max_uint256;
    require ubqToken.totalSupply(e) == 0;
    require ubqToken.balanceOf(e, currentContract) < max_uint256;
    require dollarManager.hasRole(e, dollarManager.UBQ_MINTER_ROLE(e), currentContract);
    require exposed_getReentrancyStatus(e) == REENTRANCY_STATUS_NOT_ENTERED();
    require !paused(e);

    updateStakingPool@withrevert(e, poolId);

    assert 
        lastReverted => poolId >= getStakingPoolsLength(e),
        "Method reverts unexpectedly";
}

// `updateStakingPool` does not affect other pools
rule unit_updateStakingPoolRewards_DoesNotAffectOtherPools() {
    env e;
    uint256 poolId;
    uint256 otherPoolId;

    require poolId != otherPoolId;

    LibStaking.PoolInfo otherPoolBefore = getStakingPoolInfo(e, otherPoolId);

    updateStakingPool(e, poolId);

    LibStaking.PoolInfo otherPoolAfter = getStakingPoolInfo(e, otherPoolId);

    assert otherPoolBefore == otherPoolAfter, "Other pools must not be affected";
}

//=====================
// Unit (restricted)
//=====================

// `createStakingPool` updates storage as expected
rule unit_createStakingPool_MustUpdateStorageAsExpected() {
    env e;
    uint256 allocationPoints;
    address lpToken;
    uint256 totalAllocationPointsBefore;
    uint256 totalAllocationPointsAfter;

    // 1 pool already exists
    require(getStakingPoolsLength(e) == 1);

    (_, _, _, _, _, _, totalAllocationPointsBefore, _) = getStakingSettings(e);

    createStakingPool(e, allocationPoints, lpToken);

    (_, _, _, _, _, _, totalAllocationPointsAfter, _) = getStakingSettings(e);
    LibStaking.PoolInfo poolInfo = getStakingPoolInfo(e, 1);

    assert totalAllocationPointsAfter == totalAllocationPointsBefore + allocationPoints, "Allocation points inconsistency";
    assert poolInfo.lpToken == lpToken, "Pool token mismatch";
    assert poolInfo.amount == 0, "Pool amount must be 0";
    assert poolInfo.allocationPoints == allocationPoints, "Pool's allocation points mismatch";
    assert poolInfo.accumulatedGovernancePerShare == 0, "Accumulated governance per share must be 0";
}

// `createStakingPool` must not revert unexpectedly
rule unit_createStakingPool_MustNotRevertUnexpectedly() {
    env e;
    uint256 allocationPoints;
    address lpToken;
    uint256 totalAllocationPoints;

    LibUbiquityPool.CollateralInformation collateralInformation = collateralInformation(e, lpToken);

    // prevent overflow
    (_, _, _, _, _, _, totalAllocationPoints, _) = getStakingSettings(e);
    require(totalAllocationPoints + allocationPoints < max_uint256);

    createStakingPool@withrevert(e, allocationPoints, lpToken);

    assert 
        lastReverted => (!hasRole(e, DEFAULT_ADMIN_ROLE(), e.msg.sender) || lpToken == 0 || collateralInformation.collateralAddress == lpToken),
        "Method reverts unexpectedly";
}

// `createStakingPool` does not affect other pools
rule unit_createStakingPool_DoesNotAffectOtherPools() {
    env e;
    uint256 allocationPoints;
    address lpToken;

    // 1 pool already exists
    require(getStakingPoolsLength(e) == 1);

    LibStaking.PoolInfo otherPoolInfoBefore = getStakingPoolInfo(e, 0);

    createStakingPool(e, allocationPoints, lpToken);

    LibStaking.PoolInfo otherPoolInfoAfter = getStakingPoolInfo(e, 0);

    assert 
        otherPoolInfoBefore != otherPoolInfoAfter => otherPoolInfoBefore.lastRewardBlock != otherPoolInfoAfter.lastRewardBlock, 
        "Other pool must not be affected, only last reward block may change";
}

// `setGovernanceBonusEndBlock` updates storage as expected
rule unit_setGovernanceBonusEndBlock_MustUpdateStorageAsExpected() {
    env e;
    uint256 newGovernanceBonusEndBlock;
    uint256 updatedGovernanceBonusEndBlock;

    setGovernanceBonusEndBlock(e, newGovernanceBonusEndBlock);

    (_, updatedGovernanceBonusEndBlock, _, _, _, _, _, _) = getStakingSettings(e);

    assert updatedGovernanceBonusEndBlock == newGovernanceBonusEndBlock, "Storage must be updated as expected";
}

// `setGovernanceBonusEndBlock` must not revert unexpectedly
rule unit_setGovernanceBonusEndBlock_MustNotRevertUnexpectedly() {
    env e;
    uint256 newGovernanceBonusEndBlock;

    // no pools exist
    require(getStakingPoolsLength(e) == 0);

    setGovernanceBonusEndBlock@withrevert(e, newGovernanceBonusEndBlock);

    assert 
        lastReverted => (!hasRole(e, DEFAULT_ADMIN_ROLE(), e.msg.sender) || newGovernanceBonusEndBlock < e.block.number),
        "Method reverts unexpectedly";
}

// `setGovernanceBonusMultiplier` updates storage as expected
rule unit_setGovernanceBonusMultiplier_MustUpdateStorageAsExpected() {
    env e;
    uint256 newGovernanceBonusMultiplier;
    uint256 updatedGovernanceBonusMultiplier;

    setGovernanceBonusMultiplier(e, newGovernanceBonusMultiplier);

    (_, _, updatedGovernanceBonusMultiplier, _, _, _, _, _) = getStakingSettings(e);

    assert updatedGovernanceBonusMultiplier == newGovernanceBonusMultiplier, "Storage must be updated as expected";
}

// `setGovernanceBonusMultiplier` must not revert unexpectedly
rule unit_setGovernanceBonusMultiplier_MustNotRevertUnexpectedly() {
    env e;
    uint256 newGovernanceBonusMultiplier;

    // no pools exist
    require(getStakingPoolsLength(e) == 0);

    setGovernanceBonusMultiplier@withrevert(e, newGovernanceBonusMultiplier);

    assert lastReverted => !hasRole(e, DEFAULT_ADMIN_ROLE(), e.msg.sender), "Method reverts unexpectedly";
}

// `setGovernancePerBlock` updates storage as expected
rule unit_setSetGovernancePerBlock_MustUpdateStorageAsExpected() {
    env e;
    uint256 newGovernancePerBlock;
    uint256 updatedGovernancePerBlock;

    setGovernancePerBlock(e, newGovernancePerBlock);

    (_, _, _, updatedGovernancePerBlock, _, _, _, _) = getStakingSettings(e);

    assert updatedGovernancePerBlock == newGovernancePerBlock, "Storage must be updated as expected";
}

// `setGovernancePerBlock` must not revert unexpectedly
rule unit_setGovernancePerBlock_MustNotRevertUnexpectedly() {
    env e;
    uint256 newGovernancePerBlock;

    // no pools exist
    require(getStakingPoolsLength(e) == 0);

    setGovernancePerBlock@withrevert(e, newGovernancePerBlock);

    assert 
        lastReverted => (!hasRole(e, DEFAULT_ADMIN_ROLE(), e.msg.sender) || newGovernancePerBlock < 100000000000000),
        "Method reverts unexpectedly";
}

// `setGovernanceTreasuryDivider` updates storage as expected
rule unit_setGovernanceTreasuryDivider_MustUpdateStorageAsExpected() {
    env e;
    uint256 newGovernanceTreasuryDivider;
    uint256 updatedGovernanceTreasuryDivider;

    setGovernanceTreasuryDivider(e, newGovernanceTreasuryDivider);

    (_, _, _, _, updatedGovernanceTreasuryDivider, _, _, _) = getStakingSettings(e);

    assert updatedGovernanceTreasuryDivider == newGovernanceTreasuryDivider, "Storage must be updated as expected";
}

// `setGovernanceTreasuryDivider` must not revert unexpectedly
rule unit_setGovernanceTreasuryDivider_MustNotRevertUnexpectedly() {
    env e;
    uint256 newGovernanceTreasuryDivider;

    // no pools exist
    require(getStakingPoolsLength(e) == 0);

    setGovernanceTreasuryDivider@withrevert(e, newGovernanceTreasuryDivider);

    assert 
        lastReverted => (!hasRole(e, DEFAULT_ADMIN_ROLE(), e.msg.sender) || newGovernanceTreasuryDivider == 0),
        "Method reverts unexpectedly";
}

// `setStakingRewardToken` updates storage as expected
rule unit_setStakingRewardToken_MustUpdateStorageAsExpected() {
    env e;
    address newStakingRewardToken;
    address updatedStakingRewardToken;

    setStakingRewardToken(e, newStakingRewardToken);

    (updatedStakingRewardToken, _, _, _, _, _, _, _) = getStakingSettings(e);

    assert updatedStakingRewardToken == newStakingRewardToken, "Storage must be updated as expected";
}

// `setStakingRewardToken` must not revert unexpectedly
rule unit_setStakingRewardToken_MustNotRevertUnexpectedly() {
    env e;
    address newStakingRewardToken;

    LibUbiquityPool.CollateralInformation collateralInformation = collateralInformation(e, newStakingRewardToken);

    setStakingRewardToken@withrevert(e, newStakingRewardToken);

    assert 
        lastReverted => (!hasRole(e, DEFAULT_ADMIN_ROLE(), e.msg.sender) || newStakingRewardToken == 0 || collateralInformation.collateralAddress == newStakingRewardToken),
        "Method reverts unexpectedly";
}

// `setStakingStartBlock` updates storage as expected
rule unit_setStakingStartBlock_MustUpdateStorageAsExpected() {
    env e;
    uint256 newStakingStartBlock;
    uint256 updatedStakingStartBlock;

    setStakingStartBlock(e, newStakingStartBlock);

    (_, _, _, _, _, _, _, updatedStakingStartBlock) = getStakingSettings(e);

    assert updatedStakingStartBlock == newStakingStartBlock, "Storage must be updated as expected";
}

// `setStakingStartBlock` must not revert unexpectedly
rule unit_setStakingStartBlock_MustNotRevertUnexpectedly() {
    env e;
    uint256 newStakingStartBlock;
    uint256 oldStakingStartBlock;

    (_, _, _, _, _, _, _, oldStakingStartBlock) = getStakingSettings(e);

    setStakingStartBlock@withrevert(e, newStakingStartBlock);

    assert 
        lastReverted => (!hasRole(e, DEFAULT_ADMIN_ROLE(), e.msg.sender) || newStakingStartBlock < e.block.number || newStakingStartBlock <= oldStakingStartBlock),
        "Method reverts unexpectedly";
}

// `updateStakingPool` updates storage as expected
rule unit_updateStakingPool_MustUpdateStorageAsExpected() {
    env e;
    uint256 poolId;
    uint256 allocationPoints;
    uint256 totalAllocationPointsBefore;
    uint256 totalAllocationPointsAfter;

    (_, _, _, _, _, _, totalAllocationPointsBefore, _) = getStakingSettings(e);
    LibStaking.PoolInfo poolInfoBefore = getStakingPoolInfo(e, poolId);

    updateStakingPool(e, poolId, allocationPoints);

    (_, _, _, _, _, _, totalAllocationPointsAfter, _) = getStakingSettings(e);
    LibStaking.PoolInfo poolInfoAfter = getStakingPoolInfo(e, poolId);

    assert totalAllocationPointsAfter == totalAllocationPointsBefore - poolInfoBefore.allocationPoints + allocationPoints, "Allocation points inconsistency";
    assert poolInfoAfter.allocationPoints == allocationPoints, "Pool's allocation points mismatch";
}

// `updateStakingPool` must not revert unexpectedly
rule unit_updateStakingPool_MustNotRevertUnexpectedly() {
    env e;
    uint256 poolId;
    uint256 allocationPoints;

    uint256 bonusEndBlock;
    uint256 governanceBonusMultiplier;
    uint256 governancePerBlock;
    uint256 governanceTreasuryDivider;
    uint256 rewardAmount;
    uint256 totalAllocationPoints;

    // only single pool exists
    require(getStakingPoolsLength(e) == 1);

    (_, bonusEndBlock, governanceBonusMultiplier, governancePerBlock, governanceTreasuryDivider, rewardAmount, totalAllocationPoints, _) = getStakingSettings(e);
    LibStaking.PoolInfo poolInfo = getStakingPoolInfo(e, poolId);

    // prevent overflows on pool rewards update
    require e.block.number < 2628000 * 10; // block numbers in 10 years
    require governancePerBlock < 100000000000000000000000; // 100k ether
    require governanceBonusMultiplier < 100;
    require bonusEndBlock < 2628000 * 10; // block numbers in 10 years
    require poolInfo.allocationPoints < 100000;
    require poolInfo.accumulatedGovernancePerShare == 0;
    require totalAllocationPoints > 0;
    require governanceTreasuryDivider > 0;
    require rewardAmount == 0;
    // prevent edge cases
    require(treasuryAddress(e) != 0);
    require !ubqToken.paused(e);
    require ubqToken.totalSupply(e) < max_uint256;
    require ubqToken.totalSupply(e) == 0;
    require ubqToken.balanceOf(e, currentContract) < max_uint256;
    require dollarManager.hasRole(e, dollarManager.UBQ_MINTER_ROLE(e), currentContract);
    require exposed_getReentrancyStatus(e) == REENTRANCY_STATUS_NOT_ENTERED();
    require !paused(e);
    // prevent overflows
    require(totalAllocationPoints >= poolInfo.allocationPoints);
    require(totalAllocationPoints - poolInfo.allocationPoints + allocationPoints < max_uint256);

    updateStakingPool@withrevert(e, poolId, allocationPoints);

    assert 
        lastReverted => (!hasRole(e, DEFAULT_ADMIN_ROLE(), e.msg.sender) || poolId >= getStakingPoolsLength(e)),
        "Method reverts unexpectedly";
}

// `updateStakingPool` does not affect other pools
rule unit_updateStakingPool_DoesNotAffectOtherPools() {
    env e;
    uint256 targetPoolId;
    uint256 otherPoolId;
    uint256 allocationPoints;

    LibStaking.PoolInfo otherPoolInfoBefore = getStakingPoolInfo(e, otherPoolId);

    updateStakingPool(e, targetPoolId, allocationPoints);

    LibStaking.PoolInfo otherPoolInfoAfter = getStakingPoolInfo(e, otherPoolId);

    assert otherPoolInfoBefore != otherPoolInfoAfter => otherPoolId == targetPoolId, "Other pool must not be affected";
}