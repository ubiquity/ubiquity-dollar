// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20Ubiquity} from "../../deprecated/interfaces/IERC20Ubiquity.sol";

/**
 * @notice Ubiquity staking contract
 * @dev Derived from https://github.com/sushi-labs/sushiswap/blob/271458b558afa6fdfd3e46b8eef5ee6618b60f9d/contracts/MasterChef.sol 
 */
contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Ubiquity;
    
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

    /// @notice Reward token
    IERC20Ubiquity public rewardToken;
    /// @notice Treasury address
    address public treasury;
    /// @notice Block number when bonus Governance token period ends
    uint256 public bonusEndBlock;
    /// @notice Bonus multiplier for early Governance token makers
    uint256 public governanceBonusMultiplier;
    /// @notice Governance tokens created per block
    uint256 public governancePerBlock;
    /// @notice Sets Governance token divider param for treasury. Example: if `governanceTreasuryDivider = 5` then `100 / 5 = 20%` extra minted Governance tokens for treasury.
    uint256 public governanceTreasuryDivider;
    /// @notice Total available reward amount
    uint256 public rewardAmount;
    /// @notice Info of each pool
    PoolInfo[] public poolInfo;
    /// @notice Info of each user that stakes LP tokens
    mapping(uint256 poolId => mapping(address user => UserInfo)) public userInfo;
    /// @notice Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocationPoints = 0;
    /// @notice The block number when Governance token mining starts
    uint256 public startBlock;

    //===============
    // Events
    //===============

    /// @notice Emitted on staking LP tokens
    event Stake(address indexed user, uint256 indexed poolId, uint256 amount);
    /// @notice Emitted on unstaking LP tokens
    event Unstake(address indexed user, uint256 indexed poolId, uint256 amount);

    /**
     * @notice Contract constructor
     * @param _rewardToken Reward token 
     * @param _treasury Treasury address
     * @param _governancePerBlock Governance tokens created per block
     * @param _governanceTreasuryDivider Governance token divider param for treasury. Example: if `governanceTreasuryDivider = 5` then `100 / 5 = 20%` extra minted Governance tokens for treasury.
     * @param _governanceBonusMultiplier Bonus multiplier for early Governance token makers
     * @param _startBlock Block number when Governance token mining starts
     * @param _bonusEndBlock Block number when bonus Governance token period ends
     */
    constructor(
        IERC20Ubiquity _rewardToken,
        address _treasury,
        uint256 _governancePerBlock,
        uint256 _governanceTreasuryDivider,
        uint256 _governanceBonusMultiplier,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) {
        rewardToken = _rewardToken;
        treasury = _treasury;
        governancePerBlock = _governancePerBlock;
        governanceTreasuryDivider = _governanceTreasuryDivider;
        governanceBonusMultiplier = _governanceBonusMultiplier;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
    }

    //==============
    // Views
    //==============

    /**
     * @notice View function to see pending Governance tokens on frontend
     * @param _poolId Pool id
     * @param _user User address
     * @return Staking rewards amount
     */
    function getPendingStakingRewards(uint256 _poolId, address _user)
        external
        view
        returns (uint256)
    {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][_user];
        uint256 accSushiPerShare = pool.accumulatedGovernancePerShare;
        uint256 lpSupply = pool.amount;
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier =
                getStakingMultiplier(pool.lastRewardBlock, block.number);
            uint256 sushiReward =
                multiplier.mul(governancePerBlock).mul(pool.allocationPoints).div(
                    totalAllocationPoints
                );
            accSushiPerShare = accSushiPerShare.add(
                sushiReward.mul(1e12).div(lpSupply)
            );
        }
        return user.amount.mul(accSushiPerShare).div(1e12).sub(user.rewardDebt);
    }

    /**
     * @notice Returns reward multiplier over the given `_from` to `_to` blocks
     * @param _from From block number
     * @param _to To block number
     * @return Reward multiplier
     */
    function getStakingMultiplier(uint256 _from, uint256 _to)
        public
        view
        returns (uint256)
    {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(governanceBonusMultiplier);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return
                bonusEndBlock.sub(_from).mul(governanceBonusMultiplier).add(
                    _to.sub(bonusEndBlock)
                );
        }
    }

    /**
     * @notice Returns total staking pools length
     * @return Pools length
     */
    function getStakingPoolsLength() external view returns (uint256) {
        return poolInfo.length;
    }

    //==================
    // Public methods
    //==================

    /**
     * @notice Updates reward variables for all pools
     */
    function massUpdateStakingPools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updateStakingPool(pid);
        }
    }

    /**
     * @notice Stakes LP tokens to the staking contract for Governance tokens allocation
     * @param _poolId Pool id 
     * @param _amount Amount of LP tokens to stake
     */
    function stake(uint256 _poolId, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];
        updateStakingPool(_poolId);
        if (user.amount > 0) {
            uint256 pending =
                user.amount.mul(pool.accumulatedGovernancePerShare).div(1e12).sub(
                    user.rewardDebt
                );
            safeGovernanceTransfer(msg.sender, pending);
        }
        pool.lpToken.safeTransferFrom(
            address(msg.sender),
            address(this),
            _amount
        );
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accumulatedGovernancePerShare).div(1e12);
        pool.amount = pool.amount.add(_amount);
        emit Stake(msg.sender, _poolId, _amount);
    }

    /**
     * @notice Unstakes LP tokens from the staking contract
     * @param _poolId Pool id
     * @param _amount Amount of LP tokens to unstake
     */
    function unstake(uint256 _poolId, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_poolId];
        UserInfo storage user = userInfo[_poolId][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updateStakingPool(_poolId);
        uint256 pending =
            user.amount.mul(pool.accumulatedGovernancePerShare).div(1e12).sub(
                user.rewardDebt
            );
        safeGovernanceTransfer(msg.sender, pending);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(pool.accumulatedGovernancePerShare).div(1e12);
        pool.amount = pool.amount.sub(_amount);
        pool.lpToken.safeTransfer(address(msg.sender), _amount);
        emit Unstake(msg.sender, _poolId, _amount);
    }

    /**
     * @notice Updates reward variables of the given pool to be up-to-date
     * @param _poolId Pool id
     */
    function updateStakingPool(uint256 _poolId) public {
        PoolInfo storage pool = poolInfo[_poolId];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.amount;
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getStakingMultiplier(pool.lastRewardBlock, block.number);
        uint256 sushiReward =
            multiplier.mul(governancePerBlock).mul(pool.allocationPoints).div(
                totalAllocationPoints
            );
        rewardToken.mint(treasury, sushiReward.div(governanceTreasuryDivider));
        rewardToken.mint(address(this), sushiReward);
        pool.accumulatedGovernancePerShare = pool.accumulatedGovernancePerShare.add(
            sushiReward.mul(1e12).div(lpSupply)
        );
        pool.lastRewardBlock = block.number;
        rewardAmount = rewardAmount.add(sushiReward);
    }

    //======================
    // Restricted methods
    //======================

    /**
     * @notice Adds a new staking pool
     * @param _allocationPoints Allocation points
     * @param _lpToken LP token
     * @param _withUpdate Whether to trigger update on all staking pools
     */
    function createStakingPool(
        uint256 _allocationPoints,
        IERC20 _lpToken,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdateStakingPools();
        }
        uint256 lastRewardBlock =
            block.number > startBlock ? block.number : startBlock;
        totalAllocationPoints = totalAllocationPoints.add(_allocationPoints);
        poolInfo.push(
            PoolInfo({
                lpToken: _lpToken,
                amount: 0,
                allocationPoints: _allocationPoints,
                lastRewardBlock: lastRewardBlock,
                accumulatedGovernancePerShare: 0
            })
        );
    }

    /**
     * @notice Sets bonus multiplier for early Governance token makers
     * @param _governanceBonusMultiplier Governance bonus multiplier
     */
    function setGovernanceBonusMultiplier(uint256 _governanceBonusMultiplier) public onlyOwner {
        governanceBonusMultiplier = _governanceBonusMultiplier;
    }

    /**
     * @notice Sets Governance tokens reward per block
     * @param _governancePerBlock Amount of Governance tokens minted each block
     */
    function setGovernancePerBlock(uint256 _governancePerBlock) public onlyOwner {
        governancePerBlock = _governancePerBlock;
    }

    /**
     * @notice Sets Governance token divider param for treasury. The bigger `_governanceTreasuryDivider` the less extra
     * Governance tokens will be minted for the treasury.
     * @notice Example: if `_governanceTreasuryDivider = 5` then `100 / 5 = 20%` extra minted Governance tokens for treasury
     * @param _governanceTreasuryDivider Governance divider param value
     */
    function setGovernanceTreasuryDivider(
        uint256 _governanceTreasuryDivider
    ) public onlyOwner {
        governanceTreasuryDivider = _governanceTreasuryDivider;
    }

    /**
     * @notice Updates the given pool's Governance token allocation points
     * @param _poolId Pool id
     * @param _allocationPoints New allocation points
     * @param _withUpdate Whether to trigger update on all staking pools
     */
    function updateStakingPool(
        uint256 _poolId,
        uint256 _allocationPoints,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdateStakingPools();
        }
        totalAllocationPoints = totalAllocationPoints.sub(poolInfo[_poolId].allocationPoints).add(
            _allocationPoints
        );
        poolInfo[_poolId].allocationPoints = _allocationPoints;
    }

    //====================
    // Internal helpers
    //====================

    /**
     * @notice Safe Governance token transfer function
     * @param _to Receiver address
     * @param _amount Amount to transfer
     */
    function safeGovernanceTransfer(address _to, uint256 _amount) internal {
        uint256 actualAmount = _amount > rewardAmount ? rewardAmount : _amount;
        rewardAmount = rewardAmount.sub(actualAmount);
        rewardToken.safeTransfer(_to, actualAmount);
    }

    // TODO: remove, read from `Diamond.AppStorage`
    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == treasury, "dev: wut?");
        treasury = _devaddr;
    }
}
