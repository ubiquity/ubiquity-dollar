// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {IERC20Ubiquity} from "../interfaces/IERC20Ubiquity.sol";
import {AppStorage, LibAppStorage} from "./LibAppStorage.sol";
import {LibUbiquityPool} from "./LibUbiquityPool.sol";

/**
 * @notice Ubiquity staking contract
 * @dev Derived from https://github.com/sushi-labs/sushiswap/blob/271458b558afa6fdfd3e46b8eef5ee6618b60f9d/contracts/MasterChef.sol
 */
library LibStaking {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Ubiquity;

    /// @notice Storage slot used to store data for this library
    bytes32 constant STAKING_STORAGE_POSITION =
        bytes32(uint256(keccak256("ubiquity.contracts.staking.storage")) - 1) &
            ~bytes32(uint256(0xff));

    /**
     * @notice Info of each user
     * @dev Reward debt explanation:
     *
     * We do some fancy math here. Basically, any point in time, the amount of Governance tokens
     * entitled to a user but is pending to be distributed is:
     *
     * pending reward = (user.amount * pool.accumulatedGovernancePerShare) - user.rewardDebt
     *
     * Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
     *    1. The pool's `accumulatedGovernancePerShare` (and `lastRewardBlock`) gets updated.
     *    2. User receives the pending reward sent to his/her address.
     *    3. User's `amount` gets updated.
     *    4. User's `rewardDebt` gets updated.
     */
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
    }

    /// @notice Info of each pool
    struct PoolInfo {
        IERC20 lpToken; // Address of LP token contract.
        uint256 amount; // Total amount of LP tokens staked in a pool.
        uint256 allocationPoints; // How many allocation points assigned to this pool. Governance tokens to distribute per block.
        uint256 lastRewardBlock; // Last block number that Governance tokens distribution occurs.
        uint256 accumulatedGovernancePerShare; // Accumulated Governance tokens per share, times 1e12. See below.
    }

    /// @notice Struct used as a storage for this library
    struct StakingStorage {
        /// @notice Reward token
        IERC20Ubiquity rewardToken;
        /// @notice Block number when bonus Governance token period ends
        uint256 bonusEndBlock;
        /// @notice Bonus multiplier for early Governance token makers
        uint256 governanceBonusMultiplier;
        /// @notice Governance tokens created per block
        uint256 governancePerBlock;
        /// @notice Sets Governance token divider param for treasury. Example: if `governanceTreasuryDivider = 5` then `100 / 5 = 20%` extra minted Governance tokens for treasury.
        uint256 governanceTreasuryDivider;
        /// @notice Total available reward amount
        uint256 rewardAmount;
        /// @notice Info of each pool
        PoolInfo[] poolInfo;
        /// @notice Info of each user that stakes LP tokens
        mapping(uint256 poolId => mapping(address user => UserInfo)) userInfo;
        /// @notice Total allocation points. Must be the sum of all allocation points in all pools.
        uint256 totalAllocationPoints;
        /// @notice The block number when Governance token mining starts
        uint256 startBlock;
        /// @notice Whether additional emission destinations are enabled
        bool additionalEmissionsEnabled;
        /// @notice Additional emission destinations with their ratios (basis points, e.g. 500 = 5%)
        EmissionDestination[] additionalEmissionDestinations;
    }

    /// @notice Struct representing an emission destination with its ratio
    struct EmissionDestination {
        address destination;
        uint256 ratioBps; // basis points, e.g. 500 = 5%
    }

    /**
     * @notice Returns struct used as a storage for this library
     * @return stakingStore Struct used as a storage
     */
    function stakingStorage()
        internal
        pure
        returns (StakingStorage storage stakingStore)
    {
        bytes32 position = STAKING_STORAGE_POSITION;
        assembly {
            stakingStore.slot := position
        }
    }

    //===========
    // Events
    //===========

    /// @notice Emitted when new governance bonus end block parameter set
    event GovernanceBonusEndBlockSet(
        uint256 indexed newGovernanceBonusEndBlock
    );
    /// @notice Emitted when new governance bonus multiplier parameter set
    event GovernanceBonusMultiplierSet(
        uint256 indexed newGovernanceBonusMultiplier
    );
    /// @notice Emitted when new governance per block parameter set
    event GovernancePerBlockSet(uint256 indexed newGovernancePerBlock);
    /// @notice Emitted when new governance treasury divider parameter set
    event GovernanceTreasuryDividerSet(
        uint256 indexed newGovernanceTreasuryDivider
    );
    /// @notice Emitted on staking LP tokens
    event Stake(address indexed user, uint256 indexed poolId, uint256 amount);
    /// @notice Emitted when new staking pool created
    event StakingPoolCreated(
        uint256 indexed allocationPoints,
        address indexed lpToken
    );
    /// @notice Emitted on updating staking pool rewards
    event StakingPoolUpdated(uint256 indexed poolId);
    /// @notice Emitted when staking pool allocation updated
    event StakingPoolAllocationUpdated(
        uint256 indexed poolId,
        uint256 indexed allocationPoints
    );
    /// @notice Emitted when new reward token address set
    event StakingRewardTokenSet(address indexed newRewardToken);
    /// @notice Emitted when new staking start block set
    event StakingStartBlockSet(uint256 indexed newStartBlock);
    /// @notice Emitted when additional emission destinations are updated
    event AdditionalEmissionDestinationsUpdated(EmissionDestination[] destinations);
    /// @notice Emitted when additional emissions are enabled or disabled
    event AdditionalEmissionsToggled(bool enabled);
    /// @notice Emitted on unstaking LP tokens
    event Unstake(address indexed user, uint256 indexed poolId, uint256 amount);

    //=====================
    // Views
    //=====================

    /**
     * @notice View function to see pending Governance tokens on frontend
     * @param poolId Pool id
     * @param user User address
     * @return Staking rewards amount
     */
    function getPendingStakingRewards(
        uint256 poolId,
        address user
    ) internal view returns (uint256) {
        StakingStorage storage stakingStore = stakingStorage();

        PoolInfo storage pool = stakingStore.poolInfo[poolId];
        UserInfo storage userInfo = stakingStore.userInfo[poolId][user];
        uint256 accumulatedGovernancePerShare = pool
            .accumulatedGovernancePerShare;
        uint256 lpSupply = pool.amount;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getStakingMultiplier(
                pool.lastRewardBlock,
                block.number
            );
            uint256 governanceReward = multiplier
                .mul(stakingStore.governancePerBlock)
                .mul(pool.allocationPoints)
                .div(stakingStore.totalAllocationPoints);
            accumulatedGovernancePerShare = accumulatedGovernancePerShare.add(
                governanceReward.mul(1e12).div(lpSupply)
            );
        }
        return
            userInfo.amount.mul(accumulatedGovernancePerShare).div(1e12).sub(
                userInfo.rewardDebt
            );
    }

    /**
     * @notice Returns reward multiplier over the given `from` to `to` blocks
     * @param from From block number
     * @param to To block number
     * @return Reward multiplier
     */
    function getStakingMultiplier(
        uint256 from,
        uint256 to
    ) internal view returns (uint256) {
        StakingStorage storage stakingStore = stakingStorage();

        if (to <= stakingStore.bonusEndBlock) {
            return to.sub(from).mul(stakingStore.governanceBonusMultiplier);
        } else if (from >= stakingStore.bonusEndBlock) {
            return to.sub(from);
        } else {
            return
                stakingStore
                    .bonusEndBlock
                    .sub(from)
                    .mul(stakingStore.governanceBonusMultiplier)
                    .add(to.sub(stakingStore.bonusEndBlock));
        }
    }

    /**
     * @notice Returns staking settings
     * @return Returns:
     * - Reward token address
     * - Bonus end block
     * - Governance token bonus multiplier
     * - Governance tokens minted per block
     * - Governance token divider for treasury
     * - Total available reward amount
     * - Total allocation points across all staking pools
     * - Start block when staking starts
     */
    function getStakingSettings()
        internal
        view
        returns (
            address,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        StakingStorage storage stakingStore = stakingStorage();
        return (
            address(stakingStore.rewardToken),
            stakingStore.bonusEndBlock,
            stakingStore.governanceBonusMultiplier,
            stakingStore.governancePerBlock,
            stakingStore.governanceTreasuryDivider,
            stakingStore.rewardAmount,
            stakingStore.totalAllocationPoints,
            stakingStore.startBlock
        );
    }

    /**
     * @notice View function to see user's staking info
     * @param poolId Pool id
     * @param user User address
     * @return User's staking info
     */
    function getStakingUserInfo(
        uint256 poolId,
        address user
    ) internal view returns (UserInfo memory) {
        StakingStorage storage stakingStore = stakingStorage();
        return stakingStore.userInfo[poolId][user];
    }

    /**
     * @notice View function to see pool's staking info
     * @param poolId Pool id
     * @return Pool's staking info
     */
    function getStakingPoolInfo(
        uint256 poolId
    ) internal view returns (PoolInfo memory) {
        StakingStorage storage stakingStore = stakingStorage();
        return stakingStore.poolInfo[poolId];
    }

    /**
     * @notice Returns total staking pools length
     * @return Pools length
     */
    function getStakingPoolsLength() internal view returns (uint256) {
        StakingStorage storage stakingStore = stakingStorage();
        return stakingStore.poolInfo.length;
    }

    //==================
    // Public methods
    //==================

    /**
     * @notice Updates reward variables for all pools
     */
    function massUpdateStakingPools() internal {
        StakingStorage storage stakingStore = stakingStorage();

        uint256 length = stakingStore.poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updateStakingPool(pid);
        }
    }

    /**
     * @notice Stakes LP tokens to the staking contract for Governance tokens allocation
     * @param poolId Pool id
     * @param amount Amount of LP tokens to stake
     */
    function stake(uint256 poolId, uint256 amount) internal {
        StakingStorage storage stakingStore = stakingStorage();

        PoolInfo storage pool = stakingStore.poolInfo[poolId];
        UserInfo storage user = stakingStore.userInfo[poolId][msg.sender];

        require(pool.allocationPoints > 0, "Pool disabled");

        updateStakingPool(poolId);
        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(pool.accumulatedGovernancePerShare)
                .div(1e12)
                .sub(user.rewardDebt);
            safeGovernanceTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            amount
        );
        user.amount = user.amount.add(amount);
        user.rewardDebt = user
            .amount
            .mul(pool.accumulatedGovernancePerShare)
            .div(1e12);
        pool.amount = pool.amount.add(amount);
        emit Stake(msg.sender, poolId, amount);
    }

    /**
     * @notice Unstakes LP tokens from the staking contract
     * @param poolId Pool id
     * @param amount Amount of LP tokens to unstake
     */
    function unstake(uint256 poolId, uint256 amount) internal {
        StakingStorage storage stakingStore = stakingStorage();

        PoolInfo storage pool = stakingStore.poolInfo[poolId];
        UserInfo storage user = stakingStore.userInfo[poolId][msg.sender];
        require(user.amount >= amount, "withdraw: not good");
        updateStakingPool(poolId);
        uint256 pending = user
            .amount
            .mul(pool.accumulatedGovernancePerShare)
            .div(1e12)
            .sub(user.rewardDebt);
        safeGovernanceTransfer(msg.sender, pending);
        user.amount = user.amount.sub(amount);
        user.rewardDebt = user
            .amount
            .mul(pool.accumulatedGovernancePerShare)
            .div(1e12);
        pool.amount = pool.amount.sub(amount);
        pool.lpToken.safeTransfer(address(msg.sender), amount);
        emit Unstake(msg.sender, poolId, amount);
    }

    /**
     * @notice Updates reward variables of the given pool to be up-to-date
     * @param poolId Pool id
     */
    function updateStakingPool(uint256 poolId) internal {
        AppStorage storage store = LibAppStorage.appStorage();
        StakingStorage storage stakingStore = stakingStorage();

        PoolInfo storage pool = stakingStore.poolInfo[poolId];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.amount;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getStakingMultiplier(
            pool.lastRewardBlock,
            block.number
        );
        uint256 governanceReward = multiplier
            .mul(stakingStore.governancePerBlock)
            .mul(pool.allocationPoints)
            .div(stakingStore.totalAllocationPoints);
        if (stakingStore.governanceTreasuryDivider > 0) {
            stakingStore.rewardToken.mint(
                store.treasuryAddress,
                governanceReward.div(stakingStore.governanceTreasuryDivider)
            );
        }
        // Mint additional emissions to configured destinations
        if (stakingStore.additionalEmissionsEnabled && stakingStore.additionalEmissionDestinations.length > 0) {
            for (uint256 i = 0; i < stakingStore.additionalEmissionDestinations.length; i++) {
                EmissionDestination memory dest = stakingStore.additionalEmissionDestinations[i];
                if (dest.ratioBps > 0) {
                    stakingStore.rewardToken.mint(
                        dest.destination,
                        governanceReward.mul(dest.ratioBps).div(10000)
                    );
                }
            }
        }
        stakingStore.rewardToken.mint(address(this), governanceReward);
        pool.accumulatedGovernancePerShare = pool
            .accumulatedGovernancePerShare
            .add(governanceReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
        stakingStore.rewardAmount = stakingStore.rewardAmount.add(
            governanceReward
        );
        emit StakingPoolUpdated(poolId);
    }

    //======================
    // Restricted methods
    //======================

    /**
     * @notice Adds a new staking pool
     * @notice The following LP tokens with "weird" ERC20 behavior are not supported:
     * - Fee on Transfer: https://github.com/d-xo/weird-erc20?tab=readme-ov-file#fee-on-transfer
     * - Rebasing: https://github.com/d-xo/weird-erc20?tab=readme-ov-file#balance-modifications-outside-of-transfers-rebasingairdrops
     * - Pausable Tokens: https://github.com/d-xo/weird-erc20?tab=readme-ov-file#pausable-tokens
     * - Transfer of less than amount: https://github.com/d-xo/weird-erc20?tab=readme-ov-file#transfer-of-less-than-amount
     * @param allocationPoints Allocation points
     * @param lpToken LP token, can't overlap with collateral tokens from `UbiquityPool`
     */
    function createStakingPool(
        uint256 allocationPoints,
        IERC20 lpToken
    ) internal {
        require(address(lpToken) != address(0), "Zero address detected");
        require(!LibUbiquityPool.collateralExists(address(lpToken)), "Already used as collateral");

        StakingStorage storage stakingStore = stakingStorage();

        massUpdateStakingPools();

        uint256 lastRewardBlock = block.number > stakingStore.startBlock
            ? block.number
            : stakingStore.startBlock;
        stakingStore.totalAllocationPoints = stakingStore
            .totalAllocationPoints
            .add(allocationPoints);
        stakingStore.poolInfo.push(
            PoolInfo({
                lpToken: lpToken,
                amount: 0,
                allocationPoints: allocationPoints,
                lastRewardBlock: lastRewardBlock,
                accumulatedGovernancePerShare: 0
            })
        );
        emit StakingPoolCreated(allocationPoints, address(lpToken));
    }

    /**
     * @notice Sets last block number when Governance bonus emissions end
     * @param newGovernanceBonusEndBlock Block number when Governance bonus emissions end
     */
    function setGovernanceBonusEndBlock(
        uint256 newGovernanceBonusEndBlock
    ) internal {
        require(
            newGovernanceBonusEndBlock >= block.number,
            "Bonus end block can't be in the past"
        );
        massUpdateStakingPools();
        StakingStorage storage stakingStore = stakingStorage();
        stakingStore.bonusEndBlock = newGovernanceBonusEndBlock;
        emit GovernanceBonusEndBlockSet(newGovernanceBonusEndBlock);
    }

    /**
     * @notice Sets bonus multiplier for early Governance token makers
     * @param newGovernanceBonusMultiplier New governance bonus multiplier
     */
    function setGovernanceBonusMultiplier(
        uint256 newGovernanceBonusMultiplier
    ) internal {
        massUpdateStakingPools();
        StakingStorage storage stakingStore = stakingStorage();
        stakingStore.governanceBonusMultiplier = newGovernanceBonusMultiplier;
        emit GovernanceBonusMultiplierSet(newGovernanceBonusMultiplier);
    }

    /**
     * @notice Sets Governance tokens reward per block
     * @dev If `newGovernancePerBlock < 0.0001 ether` users may end up getting 0 rewards 
     * if staked amount > 1_000_000_000e18
     * @param newGovernancePerBlock New amount of Governance tokens minted each block
     */
    function setGovernancePerBlock(uint256 newGovernancePerBlock) internal {
        require(newGovernancePerBlock >= 0.0001 ether, "Rewards are too small");
        massUpdateStakingPools();
        StakingStorage storage stakingStore = stakingStorage();
        stakingStore.governancePerBlock = newGovernancePerBlock;
        emit GovernancePerBlockSet(newGovernancePerBlock);
    }

    /**
     * @notice Sets Governance token divider param for treasury. The bigger `governanceTreasuryDivider` the less extra
     * Governance tokens will be minted for the treasury.
     * @notice Example: if `governanceTreasuryDivider = 5` then `100 / 5 = 20%` extra minted Governance tokens for treasury
     * @notice Set `governanceTreasuryDivider` to 0 if you want to disable minting rewards to the treasury
     * @param newGovernanceTreasuryDivider New governance divider param value
     */
    function setGovernanceTreasuryDivider(
        uint256 newGovernanceTreasuryDivider
    ) internal {
        massUpdateStakingPools();
        StakingStorage storage stakingStore = stakingStorage();
        stakingStore.governanceTreasuryDivider = newGovernanceTreasuryDivider;
        emit GovernanceTreasuryDividerSet(newGovernanceTreasuryDivider);
    }

    /**
     * @notice Sets staking reward token
     * @notice The following reward tokens with "weird" ERC20 behavior are not supported:
     * - Rebasing: https://github.com/d-xo/weird-erc20?tab=readme-ov-file#balance-modifications-outside-of-transfers-rebasingairdrops
     * - Pausable Tokens: https://github.com/d-xo/weird-erc20?tab=readme-ov-file#pausable-tokens
     * - Transfer of less than amount: https://github.com/d-xo/weird-erc20?tab=readme-ov-file#transfer-of-less-than-amount
     * @param newRewardToken New reward token address, can't overlap with collateral tokens from `UbiquityPool`
     */
    function setStakingRewardToken(address newRewardToken) internal {
        require(newRewardToken != address(0), "Zero address detected");
        require(!LibUbiquityPool.collateralExists(newRewardToken), "Already used as collateral");
        StakingStorage storage stakingStore = stakingStorage();
        stakingStore.rewardToken = IERC20Ubiquity(newRewardToken);
        emit StakingRewardTokenSet(newRewardToken);
    }

    /**
     * @notice Sets start block when staking should be active
     * @param newStartBlock Block number when staking should be active
     */
    function setStakingStartBlock(uint256 newStartBlock) internal {
        require(newStartBlock >= block.number, "Can't start in the past");

        StakingStorage storage stakingStore = stakingStorage();
        require(newStartBlock > stakingStore.startBlock, "Must be greater than the previous start block");

        stakingStore.startBlock = newStartBlock;
        emit StakingStartBlockSet(newStartBlock);
    }

    /**
     * @notice Updates the given pool's Governance token allocation points
     * @param poolId Pool id
     * @param allocationPoints New allocation points
     */
    function updateStakingPool(
        uint256 poolId,
        uint256 allocationPoints
    ) internal {
        StakingStorage storage stakingStore = stakingStorage();

        require(poolId < stakingStore.poolInfo.length, "Pool does not exist");

        massUpdateStakingPools();

        stakingStore.totalAllocationPoints = stakingStore
            .totalAllocationPoints
            .sub(stakingStore.poolInfo[poolId].allocationPoints)
            .add(allocationPoints);
        stakingStore.poolInfo[poolId].allocationPoints = allocationPoints;

        emit StakingPoolAllocationUpdated(poolId, allocationPoints);
    }

    /**
     * @notice Sets additional emission destinations for governance tokens
     * @dev Each destination has a ratio in basis points (e.g. 500 = 5%)
     * @param destinations Array of emission destinations with their ratios
     */
    function setAdditionalEmissionDestinations(
        EmissionDestination[] memory destinations
    ) internal {
        StakingStorage storage stakingStore = stakingStorage();
        massUpdateStakingPools();
        
        // Validate total ratio doesn't exceed 10000 bps (100%)
        uint256 totalRatio;
        for (uint256 i = 0; i < destinations.length; i++) {
            require(destinations[i].destination != address(0), "Zero address detected");
            require(destinations[i].ratioBps <= 10000, "Ratio exceeds 100%");
            totalRatio += destinations[i].ratioBps;
        }
        require(totalRatio <= 10000, "Total ratio exceeds 100%");
        
        // Clear and repopulate the array
        delete stakingStore.additionalEmissionDestinations;
        for (uint256 i = 0; i < destinations.length; i++) {
            stakingStore.additionalEmissionDestinations.push(destinations[i]);
        }
        emit AdditionalEmissionDestinationsUpdated(destinations);
    }

    /**
     * @notice Toggles additional emissions on/off
     * @param enabled Whether additional emissions should be enabled
     */
    function setAdditionalEmissionsEnabled(bool enabled) internal {
        StakingStorage storage stakingStore = stakingStorage();
        stakingStore.additionalEmissionsEnabled = enabled;
        emit AdditionalEmissionsToggled(enabled);
    }

    /**
     * @notice Returns additional emission destinations and their status
     * @return enabled Whether additional emissions are enabled
     * @return destinations Array of emission destinations
     */
    function getAdditionalEmissionDestinations()
        internal
        view
        returns (bool enabled, EmissionDestination[] memory destinations)
    {
        StakingStorage storage stakingStore = stakingStorage();
        return (
            stakingStore.additionalEmissionsEnabled,
            stakingStore.additionalEmissionDestinations
        );
    }

    //====================
    // Internal helpers
    //====================

    /**
     * @notice Safe Governance token transfer function
     * @param to Receiver address
     * @param amount Amount to transfer
     */
    function safeGovernanceTransfer(address to, uint256 amount) internal {
        StakingStorage storage stakingStore = stakingStorage();

        uint256 actualAmount = amount > stakingStore.rewardAmount
            ? stakingStore.rewardAmount
            : amount;
        stakingStore.rewardAmount = stakingStore.rewardAmount.sub(actualAmount);
        stakingStore.rewardToken.safeTransfer(to, actualAmount);
    }
}
